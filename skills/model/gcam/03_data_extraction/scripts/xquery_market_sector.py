#!/usr/bin/env python
"""Extract GCAM market and sector-cost rows via BaseX XQuery.

Accepts scenario, region, sector, and year lists as command-line arguments.
No pre-built sector registry required.

Usage:
  python xquery_market_sector.py \
    --scenarios DPEC_SSP1,DPEC_SSP1_Peak2030_NDC2035 \
    --sectors cement,"iron and steel",coke \
    --years 2021,2025,2030,2035 \
    --out-dir $env:UNIT_PRICE_OUT_DIR
"""

from __future__ import annotations

import argparse
import math
import os
import subprocess
from io import StringIO
from pathlib import Path

import pandas as pd


def resolve_root() -> Path:
    release = os.environ.get("GCAM_RELEASE_DIR", "")
    if release:
        return Path(release)
    raise RuntimeError("Set GCAM_RELEASE_DIR environment variable")


def resolve_out() -> Path:
    out = os.environ.get("UNIT_PRICE_OUT_DIR", os.environ.get("AIRMOSAIC_LOCAL_WORKSPACE", ""))
    if out:
        p = Path(out)
    else:
        p = Path.cwd()
    p.mkdir(parents=True, exist_ok=True)
    return p


def xq_quote(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def xq_list(values: list[str]) -> str:
    return "(" + ",".join(xq_quote(v) for v in values) + ")"


def xq_number_list(values: list[int]) -> str:
    return "(" + ",".join(str(v) for v in values) + ")"


def locate_basex_jar(release: Path) -> Path:
    candidates = list(release.glob("libs/jars/BaseX-*.jar"))
    if candidates:
        return candidates[0]
    raise FileNotFoundError(f"No BaseX jar found under {release}/libs/jars/")


def run_basex(scenario: str, query: str, release: Path, basex_jar: Path, out: Path) -> str:
    q = out / f"_tmp_xquery_market_sector_{scenario}.xq"
    q.write_text(query, encoding="utf-8")
    cmd = [
        "java", "-Xmx1g",
        f"-Dorg.basex.DBPATH=output\{scenario}",
        "-cp", str(basex_jar.relative_to(release)),
        "org.basex.BaseX",
        "-i", "database_basexdb", "RUN", str(q),
    ]
    proc = subprocess.run(cmd, cwd=release, text=True, encoding="utf-8",
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    q.unlink(missing_ok=True)
    if proc.returncode != 0:
        raise RuntimeError(f"{scenario} BaseX failed: {proc.stderr[:1000]}")
    return proc.stdout


def build_market_query(scenario: str, regions: list[str], sectors: list[str],
                       years: list[int]) -> str:
    return f"""
let $regions := {xq_list(regions)}
let $sectors := {xq_list(sectors)}
let $years := {xq_number_list(years)}
return (
  string-join(("scenario","source","region","sector","year",
    "price","quantity","output_unit","price_unit","node_name","market_type"), "	"),
  codepoints-to-string(10),
  for $s in (collection()/scenario[@name = "{scenario}"])[last()]
  for $m in $s/world/Marketplace/market[number(@year) = $years
    and string(MarketRegion) = $regions
    and string(MarketGoodOrFuel) = $sectors]
  let $outUnit := string(($m/Info/Pair[Key = "output-unit"]/Value)[1])
  let $priceUnit := string(($m/Info/Pair[Key = "price-unit"]/Value)[1])
  return (
    string-join((
      string($s/@name), "marketplace", string($m/MarketRegion),
      string($m/MarketGoodOrFuel), string($m/@year),
      string($m/price), string($m/supply),
      $outUnit, $priceUnit,
      string($m/@name), string($m/@type)
    ), "	"),
    codepoints-to-string(10)
  ),
  for $s in (collection()/scenario[@name = "{scenario}"])[last()]
  for $r in $s/world/*[@type = "region" and string(@name) = $regions]
  for $sec in $r/*[@type = "sector" and string(@name) = $sectors]
  for $cost in $sec/cost[number(@year) = $years]
  let $year := string($cost/@year)
  let $price := string($cost)
  let $quantity := string(sum(
    $sec//*[@type = "output"]/physical-output[@vintage = $year]/number(.)
  ))
  let $outUnit := string((
    $sec//*[@type = "output"]/physical-output[@vintage = $year]/@unit,
    $sec//*[@type = "output"]/physical-output/@unit
  )[1])
  where $price != ""
  return (
    string-join((
      string($s/@name), "sector_cost", string($r/@name),
      string($sec/@name), $year, $price, $quantity,
      $outUnit, "", name($sec), string($sec/@type)
    ), "	"),
    codepoints-to-string(10)
  )
)
"""


def weighted_price(group: pd.DataFrame) -> float:
    price = pd.to_numeric(group["price"], errors="coerce")
    quantity = pd.to_numeric(group["quantity"], errors="coerce").fillna(0).clip(lower=0)
    valid = price.notna()
    if quantity[valid].sum() > 1e-12:
        return float((price[valid] * quantity[valid]).sum() / quantity[valid].sum())
    if valid.any():
        return float(price[valid].mean())
    return math.nan


def main() -> None:
    p = argparse.ArgumentParser(description="Extract GCAM market and sector rows via BaseX")
    p.add_argument("--scenarios", required=True, help="Comma-separated scenario names")
    p.add_argument("--regions", default="China,AH,BJ,CQ,FJ,GS,GD,GX,GZ,HI,HE,HL,HA,HB,HN,NM,JS,JX,JL,LN,NX,QH,SN,SD,SH,SX,SC,TJ,XZ,XJ,YN,ZJ")
    p.add_argument("--sectors", required=True, help="Comma-separated sector names")
    p.add_argument("--years", default="2021,2025,2030,2035", help="Comma-separated years")
    p.add_argument("--out-dir", default=None, help="Output directory")
    args = p.parse_args()

    release = resolve_root()
    out_dir = Path(args.out_dir) if args.out_dir else resolve_out()
    basex_jar = locate_basex_jar(release)
    scenarios = [s.strip() for s in args.scenarios.split(",") if s.strip()]
    regions = [r.strip() for r in args.regions.split(",") if r.strip()]
    sectors = [s.strip() for s in args.sectors.split(",") if s.strip()]
    years = [int(y.strip()) for y in args.years.split(",") if y.strip()]

    frames = []
    for scenario in scenarios:
        query = build_market_query(scenario, regions, sectors, years)
        raw = run_basex(scenario, query, release, basex_jar, out_dir)
        part = pd.read_csv(StringIO(raw), sep="	").dropna(how="all")
        frames.append(part)

    df = pd.concat(frames, ignore_index=True)
    rows_path = out_dir / "market_sector_rows.csv"
    df.to_csv(rows_path, index=False, encoding="utf-8-sig")

    # Summary
    summary = df.groupby(["scenario", "source", "sector", "year"], dropna=False).apply(
        lambda g: pd.Series({
            "weighted_price": weighted_price(g),
            "quantity_sum": pd.to_numeric(g["quantity"], errors="coerce").sum(),
            "province_count": g["region"].nunique(),
            "price_unit": ";".join(sorted(set(g["price_unit"].dropna().astype(str)))),
            "output_unit": ";".join(sorted(set(g["output_unit"].dropna().astype(str)))),
        })
    ).reset_index()
    summary_path = out_dir / "market_sector_summary.csv"
    summary.to_csv(summary_path, index=False, encoding="utf-8-sig")

    print(f"Wrote {rows_path} rows={len(df)}")
    print(f"Wrote {summary_path} rows={len(summary)}")


if __name__ == "__main__":
    main()
