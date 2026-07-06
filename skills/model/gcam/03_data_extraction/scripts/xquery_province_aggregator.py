#!/usr/bin/env python
"""Aggregate province-level GCAM rows to weighted national totals.

Reads market_sector_rows.csv and computes weighted prices and quantity sums.

Usage:
  python xquery_province_aggregator.py \
    --input-csv $env:UNIT_PRICE_OUT_DIR/market_sector_rows.csv
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

import pandas as pd


def wmean(price: pd.Series, quantity: pd.Series) -> float:
    ok = price.notna() & quantity.notna()
    if not ok.any():
        return math.nan
    w = quantity[ok].clip(lower=0)
    p = price[ok]
    if w.sum() <= 1e-12:
        return float(p.mean())
    return float((p * w).sum() / w.sum())


def main() -> None:
    p = argparse.ArgumentParser(description="Aggregate province-level GCAM rows")
    p.add_argument("--input-csv", required=True)
    p.add_argument("--out-dir", default=None)
    args = p.parse_args()

    in_csv = Path(args.input_csv)
    if not in_csv.exists():
        raise FileNotFoundError(f"Input not found: {in_csv}")

    out_dir = Path(args.out_dir) if args.out_dir else in_csv.parent

    df = pd.read_csv(in_csv, encoding="utf-8-sig")
    for c in ["price", "quantity"]:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")

    # Aggregate: only use province rows (not China aggregate)
    province = df[~df["region"].isin(["China", "Global"])].copy()
    province["year"] = province["year"].astype(int)

    agg = province.groupby(["scenario", "source", "sector", "year"], dropna=False).apply(
        lambda g: pd.Series({
            "weighted_price": wmean(g["price"], g["quantity"]),
            "quantity_sum": g["quantity"].sum(),
            "province_count": g["region"].nunique(),
        })
    ).reset_index()

    out_path = out_dir / "province_aggregate.csv"
    agg.to_csv(out_path, index=False, encoding="utf-8-sig")
    print(f"Wrote {out_path} rows={len(agg)}")


if __name__ == "__main__":
    main()
