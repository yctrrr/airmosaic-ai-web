#!/usr/bin/env python
"""Extract GCAM technology-level component rows via BaseX XQuery.

Decomposes sector cost into energy, non-energy, capital, and carbon components.

Usage:
  python xquery_technology_components.py \
    --scenarios DPEC_SSP1 \
    --sectors cement,"iron and steel" \
    --years 2021,2025,2030,2035
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
    p = Path(out) if out else Path.cwd()
    p.mkdir(parents=True, exist_ok=True)
    return p


def locate_basex_jar(release: Path) -> Path:
    candidates = list(release.glob("libs/jars/BaseX-*.jar"))
    if candidates:
        return candidates[0]
    raise FileNotFoundError(f"No BaseX jar under {release}/libs/jars/")


def xq_quote(v: str) -> str:
    return '"' + v.replace('"', '""') + '"'


def xq_list(vs: list[str]) -> str:
    return "(" + ",".join(xq_quote(v) for v in vs) + ")"


def xq_number_list(vs: list[int]) -> str:
    return "(" + ",".join(str(v) for v in vs) + ")"


def run_basex(scenario: str, query: str, release: Path, basex_jar: Path, out: Path) -> str:
    q = out / f"_tmp_xquery_tech_{scenario}.xq"
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


def build_tech_query(scenario: str, regions: list[str], sectors: list[str],
                     years: list[int]) -> str:
    return f"""
let $regions := {xq_list(regions)}
let $sectors := {xq_list(sectors)}
let $years := {xq_number_list(years)}
return (
  string-join(("scenario","region","sector","subsector","technology",
    "year","sector_cost","tech_cost","tech_output","output_unit",
    "co2_emissions","component_type","component_node","component_name",
    "io_coefficient","demand_physical","component_price",
    "component_price_source","secondary_output","carbon_content"), "	"),
  codepoints-to-string(10),
  for $s in (collection()/scenario[@name = "{scenario}"])[last()]
  for $r in $s/world/*[@type = "region" and string(@name) = $regions]
  for $sec in $r/*[@type = "sector" and string(@name) = $sectors]
  for $sub in $sec/*[@type = "subsector"]
  for $tech in $sub/*[@type = "technology"]
  let $y := number($tech/@year)
  let $secCost := string(($sec/cost[@year = $y])[1])
  let $cost := string(($tech/cost[@year = $y], $tech/cost[number(@year) <= $y][last()])[1])
  let $techOutput := sum($tech/*[@type = "output"]/physical-output[@vintage = $y]/number(.))
  let $outputUnit := string((
    $tech/*[@type = "output"]/physical-output[@vintage = $y]/@unit,
    $sec//*[@type = "output"]/physical-output[@vintage = $y]/@unit
  )[1])
  let $co2 := sum($tech/CO2/emissions[@year = $y]/number(.))
  where $y = $years and $secCost != "" and $techOutput > 0
  for $inp in $tech/input
  let $inputName := string($inp/@name)
  let $coef := string(($inp/IO-coefficient[@year = $y], $inp/IO-coefficient)[1])
  let $demand := string(($inp/demand-physical[@vintage = $y])[1])
  let $inputPrice := string(($inp/price-paid[@year = $y], $inp/price-paid)[1])
  let $carbon := string(($inp/carbon-content[@vintage = $y], $inp/carbon-content)[1])
  return (
    string-join((
      string($s/@name), string($r/@name), string($sec/@name),
      string($sub/@name), string($tech/@name),
      string($y), $secCost, string($cost), string($techOutput),
      $outputUnit, string($co2),
      "input", name($inp), $inputName,
      $coef, $demand, $inputPrice, "input_price", "", $carbon
    ), "	"),
    codepoints-to-string(10)
  )
)
"""


def wmean(df: pd.DataFrame, col: str, weight: str) -> float:
    v = df[col]
    w = df[weight]
    ok = v.notna() & w.notna() & (w > 0)
    if not ok.any():
        return math.nan
    return float((v[ok] * w[ok]).sum() / w[ok].sum())


def main() -> None:
    p = argparse.ArgumentParser(description="Extract GCAM technology component rows")
    p.add_argument("--scenarios", required=True)
    p.add_argument("--regions", default="China,AH,BJ,CQ,FJ,GS,GD,GX,GZ,HI,HE,HL,HA,HB,HN,NM,JS,JX,JL,LN,NX,QH,SN,SD,SH,SX,SC,TJ,XZ,XJ,YN,ZJ")
    p.add_argument("--sectors", required=True)
    p.add_argument("--years", default="2021,2025,2030,2035")
    p.add_argument("--out-dir", default=None)
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
        query = build_tech_query(scenario, regions, sectors, years)
        raw = run_basex(scenario, query, release, basex_jar, out_dir)
        part = pd.read_csv(StringIO(raw), sep="	").dropna(how="all")
        frames.append(part)

    df = pd.concat(frames, ignore_index=True)
    for c in ["sector_cost","tech_cost","tech_output","co2_emissions","io_coefficient","demand_physical","component_price"]:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")

    rows_path = out_dir / "technology_component_rows.csv"
    df.to_csv(rows_path, index=False, encoding="utf-8-sig")

    by_key = ["scenario","region","sector","year"]
    col_names = [c for c in df.columns if c not in by_key]
    numeric_cols = [c for c in col_names if df[c].dtype in ("float64","int64")]
    summary = df.groupby(by_key, dropna=False).apply(
        lambda g: pd.Series({c: wmean(g, c, "tech_output") for c in numeric_cols})
    ).reset_index()
    summary_path = out_dir / "technology_component_summary.csv"
    summary.to_csv(summary_path, index=False, encoding="utf-8-sig")

    print(f"Wrote {rows_path} rows={len(df)}")
    print(f"Wrote {summary_path} rows={len(summary)}")


if __name__ == "__main__":
    main()
