# GCAM Output Price and Quantity Units

## Key Concept

GCAM sector output uses two independent unit fields:

- `output-unit`: unit of `physical-output` (e.g. Mt, EJ, Mt NH3)
- `price-unit`: unit of `sector/cost` (e.g. 1975$/kg, 1975$/GJ, 1975$/kgNH3)

These two units are NOT always compatible. The product `sector/cost * physical-output` only represents a monetary proxy when the units are closed (e.g. Mt * 1975$/kg can be converted because Mt -> kg is a known factor).

## Decision Rule

Before interpreting `cost * output` as revenue, check unit compatibility:

1. If both units refer to the same physical commodity (e.g. `Mt` and `1975$/kg` for cement), the product can be converted to 1975$ by applying the correct scale factor.

2. If `output-unit` is energy-based (`EJ`) and `price-unit` is energy-based (`1975$/GJ`), the product represents a service expenditure proxy, not a physical commodity revenue. This is common for `chemical` and `other industry`.

3. If the units are mismatched (e.g. `Mt` output, `1975$/GJ` price, as seen in some GCAM-China configurations for iron and steel), the product is not directly interpretable as revenue. The sector's `price-unit` should be confirmed in the model input configuration.

## Example from GCAM-China

| sector           | output_unit | price_unit    | compatible for revenue proxy? |
| ---------------- | ----------- | ------------- | ----------------------------- |
| `ammonia`        | `Mt NH3`    | `1975$/kgNH3` | yes (Mt -> kg conversion)     |
| `cement`         | `Mt`        | `1975$/kg`    | yes (Mt -> kg conversion)     |
| `chemical`       | `EJ`        | `1975$/GJ`    | yes, but as service proxy     |
| `other industry` | `EJ`        | `1975$/GJ`    | yes, but as service proxy     |
| `iron and steel` | `Mt`        | `1975$/GJ`    | NOT compatible; check config  |

## Where Units Come From

Both `price-unit` and `output-unit` are defined in the GCAM input XML for each sector. They are set via input CSV files and written by R processing scripts into the model XML. BaseX output faithfully reflects whatever was loaded into the model.

In GCAM-China, these are typically set in files like:
- `A323.sector.csv` or `A323.sector_China.csv` for detailed industry
- `A321.sector.csv` for cement
- Generated XML like `detailed_industry_CHINA.xml`, `cement_CHINA.xml`

A mismatch in the input configuration (e.g. iron and steel with `price-unit=1975$/GJ` but `output-unit=Mt`) flows through to BaseX output. This should be addressed at the input configuration level.

## Reference

GCAM official documentation:
- Price Outputs: https://jgcri.github.io/gcam-doc/outputs_prices.html
- Quantity Outputs: https://jgcri.github.io/gcam-doc/outputs_quantity.html
- Energy Demand: https://jgcri.github.io/gcam-doc/demand_energy.html
