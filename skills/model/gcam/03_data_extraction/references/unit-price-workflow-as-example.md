# Unit Price Extraction As Worked Example

This reference explains the unit price workflow as a concrete application of the generic patterns in this layer. It is the first worked example. Follow the same approach for other extraction tasks.

## Pipeline

```
xquery_market_sector.py       -> market_sector_rows.csv       -> market_sector_summary.csv
xquery_technology_components.py -> component_rows.csv         -> component_summary.csv
xquery_province_aggregator.py   -> province_cost_change.xlsx
plot_sector_change.R            -> key_sector_change.png
```

## Step 1: Extract Market and Sector Rows

Input: scenario names, region list, sector names, year list, BaseX databases.
Output: combined CSV with `source` column indicating "marketplace" or "sector_cost".

This step queries both `Marketplace/market` and `sector/cost` nodes, merging them into a unified table with consistent columns.

## Step 2: Extract Technology Components

Input: scenario names, region list, sector names, year list, BaseX databases.
Output: component rows with technology-level detail.

Decomposes sector cost into energy/materials, non-energy, capital, CO2, and secondary credits. See `technology-component-logic.md` for the full methodology.

## Step 3: Aggregate Province Rows

Input: market_sector_rows.csv from Step 1.
Output: national weighted prices and total quantities.

Computes weighted averages from province-level data:

```python
weighted_price = sum(price_i * quantity_i) / sum(quantity_i)
total_quantity = sum(quantity_i)
```

## Step 4: Plot

Input: market_sector_rows.csv from Step 1, sector filter, scenario filter.
Output: PNG plots with boxplots, weighted means, and change arrows comparing scenarios.

## Output Fields

Final explainability table fields:

| field | meaning |
|-------|---------|
| `selected_unit_price` | final sector/market-level unit price |
| `selected_quantity` | physical output corresponding to the price |
| `selected_aggregation_scope` | `province_aggregate` or `china_reported` |
| `weighted_tech_cost` | component-decomposition technology cost |
| `weighted_sector_cost` | sector cost reweighted over component sample |
| `explainability_quality` | quality category for component explanation |

## Unit Price Selection Logic

When both marketplace and sector cost rows are available, select the best unit price proxy:

1. **Prefer `sector_cost + province_aggregate`**: Most representative of actual sector economics. Province-level sector costs weighted by output.
2. **Fallback `marketplace + china_reported`**: If sector cost is unavailable, use China-reported marketplace price.
3. **Last resort `marketplace + province_aggregate`**: Province-level marketplace aggregation.

The selection also considers unit compatibility. For sectors where `price-unit` and `output-unit` are incompatible (e.g., iron and steel: `1975$/GJ` price, `Mt` output), the `selected_unit_price` should not be used to compute revenue without unit conversion. Mark such rows appropriately.

## Expected Unit Differences

`weighted_sector_cost` may differ from `selected_unit_price` because it is reweighted over the component technology sample rather than using all technologies. `weighted_tech_cost` may differ further because it represents the leaf technology cost before price feedback.

These differences are diagnostics, not errors. The `explainability_quality` field rates how well the decomposition explains the sector price:

| Quality | Condition |
|---------|-----------|
| `good` | Residual between weighted_tech_cost and summed components < 10% |
| `acceptable` | Residual < 25% |
| `poor` | Residual >= 25% or missing major cost components |

## Unit Override Considerations

Some sectors need explicit unit overrides because GCAM-China input configuration assigns energy-based price units to mass-output sectors (see `price-unit-interpretation.md`). When applying overrides:

1. Document which sectors received overrides
2. Record the original and overridden units
3. Note that revenue calculations using overridden units are proxies, not direct GCAM outputs
