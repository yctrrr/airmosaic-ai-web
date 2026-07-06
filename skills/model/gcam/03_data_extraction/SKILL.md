---
name: gcam-data-extraction
description: Extract GCAM scenario output data using parameterized XQuery. Supports market rows, sector costs, technology components, provincial aggregation, and plotting. Use unit price extraction as the first worked example; apply the same pattern to industrial output, technology I/O, emissions, or energy demand.
---

# GCAM Data Extraction

## Purpose

This layer provides parameterized scripts for extracting data from GCAM BaseX output databases. All scripts accept scenario names, region lists, sector names, and year lists as arguments. No pre-built sector registry is required.

The unit price workflow serves as the first worked example. The same patterns apply to other extraction tasks.

## Prerequisites

```powershell
$env:GCAM_RELEASE_DIR = "<path to gcam-china-v8-Windows-Release-Package>"
$env:UNIT_PRICE_OUT_DIR = "${AIRMOSAIC_LOCAL_WORKSPACE}/outputs/gcam"
```

BaseX database must exist at:
```text
$env:GCAM_RELEASE_DIR/output/<scenario>/database_basexdb/
```

## Extraction Tools

### `xquery_market_sector.py`

Extracts market rows (Marketplace/market) and sector cost rows for specified scenarios, regions, sectors, and years. Outputs a combined CSV with price, quantity, unit columns.

Parameters: `--scenarios`, `--regions`, `--sectors`, `--years`, `--out-dir`

### `xquery_technology_components.py`

Extracts technology-level component rows including input coefficients, demand, prices, secondary outputs, and CO2 emissions. Decomposes sector cost into energy, non-energy, capital, and carbon components.

Parameters: `--scenarios`, `--regions`, `--sectors`, `--years`, `--out-dir`, `--method` (generic or transport)

### `xquery_province_aggregator.py`

Aggregates province-level rows to weighted national values. Computes weighted prices and total quantities.

Parameters: `--input-csv`, `--out-dir`

### `plot_sector_change.R`

Plots sector price or quantity changes between two years, with boxplots, weighted means, and change arrows.

Parameters: `--sectors`, `--scenarios`, `--input-csv`, `--out-dir`

## Workflow Example: Unit Price

```powershell
# Step 1: Extract market and sector rows
python xquery_market_sector.py \
  --scenarios DPEC_SSP1,DPEC_SSP1_Peak2030_NDC2035 \
  --sectors cement,"iron and steel",coke \
  --years 2021,2025,2030,2035

# Step 2: Extract technology components
python xquery_technology_components.py \
  --scenarios DPEC_SSP1 \
  --sectors cement \
  --years 2021,2025,2030,2035

# Step 3: Aggregate province rows
python xquery_province_aggregator.py \
  --input-csv $env:UNIT_PRICE_OUT_DIR/market_sector_rows.csv

# Step 4: Plot
Rscript plot_sector_change.R \
  --sectors "cement,coke,iron and steel" \
  --input-csv $env:UNIT_PRICE_OUT_DIR/market_sector_rows.csv
```

## Agent Contract

External agents should call wrappers:
- `extract_gcam_market_sector_data`
- `extract_gcam_technology_components`
- `aggregate_gcam_province_data`
- `plot_gcam_sector_change`

The agent must not receive direct BaseX execution or unrestricted filesystem access.

## References

- `references/xquery-patterns-price-quantity.md`: XQuery for price and quantity extraction
- `references/xquery-patterns-technology-inputs.md`: XQuery for technology components
- `references/unit-price-workflow-as-example.md`: step-by-step unit price example
- `references/output-unit-compatibility.md`: price/quantity unit compatibility
- `references/price-unit-interpretation.md`: detailed price unit interpretation and sector-specific quirks
- `references/technology-component-logic.md`: how sector costs decompose into technology components
