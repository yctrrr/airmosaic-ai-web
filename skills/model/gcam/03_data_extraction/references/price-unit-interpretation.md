# Price Unit Interpretation

How to interpret GCAM price units, the difference between output-unit and price-unit, and sector-specific unit quirks in GCAM-China.

## Two Independent Unit Systems

Every GCAM sector has two units defined independently:

- **`output-unit`**: The unit of `physical-output`. Examples: `Mt`, `EJ`, `Mt NH3`.
- **`price-unit`**: The unit of `sector/cost`. Examples: `1975$/kg`, `1975$/GJ`, `1975$/kgNH3`.

The `1975$` prefix means the price is in constant 1975 US dollars, the standard GCAM currency baseline.

## Compatibility for Revenue Calculation

Direct multiplication `cost * output` only produces a meaningful monetary proxy when units are dimensionally compatible:

| Case | Output Unit | Price Unit | Compatible | Notes |
|------|------------|------------|------------|-------|
| Mass-mass | `Mt` | `1975$/kg` | Yes | Mt * $/kg = 10^9 * $ (Mt->kg factor) |
| Energy-energy | `EJ` | `1975$/GJ` | Yes | EJ * $/GJ = 10^9 * $ (service proxy) |
| Mixed | `Mt` | `1975$/GJ` | No | Physical dimensions mismatch |

## GCAM-China Sector Unit Reference

Confirmed from `A323.sector_China.csv`:

| Sector | output-unit | price-unit (GCAM-China) | price-unit (GCAM-Core) | Revenue Proxy? |
|--------|------------|------------------------|----------------------|----------------|
| cement | Mt | 1975$/kg | 1975$/kg | Yes |
| iron and steel | Mt | 1975$/GJ | 1975$/kg | No (mixed in China) |
| coke | Mt | 1975$/GJ | N/A (not a sector) | No (mixed) |
| chemical | EJ | 1975$/GJ | 1975$/GJ | Yes (service proxy) |
| other industry | EJ | 1975$/GJ | 1975$/GJ | Yes (service proxy) |
| ammonia | Mt NH3 | 1975$/kgNH3 | N/A | Yes (Mt->kg conversion) |
| aluminum | Mt | 1975$/kg | 1975$/kg | Yes |
| paper | Mt | 1975$/kg | 1975$/kg | Yes |
| food processing | Mt | 1975$/kg | 1975$/kg | Yes |

## Why Iron and Steel Uses 1975$/GJ in GCAM-China

In official GCAM-Core, `iron and steel` uses `price-unit=1975$/kg`. GCAM-China changed this to `1975$/GJ`, likely because the iron and steel sector represents an energy service rather than a pure mass commodity in the China model. Input coefficients are defined as GJ/ton, and the model resolution uses energy flows.

This means:
- `sector/cost` for iron and steel is in 1975$/GJ
- `physical-output` is in Mt
- Direct multiplication is not interpretable as revenue
- For revenue comparison, either use marketplace prices (if available) or apply external unit conversion

## Coke: A GCAM-China Extension

Coke does not exist in official GCAM-Core as a standalone sector. In GCAM-China:
- It is an independent `supplysector name="coke"`
- `output-unit=Mt` (physical mass)
- `price-unit=1975$/GJ` (energy-based price)
- Similarly mixed units as iron and steel

## Where Marketplace Prices Help

The GCAM Marketplace (`Marketplace/market` nodes) records transaction prices and quantities for goods traded between sectors. Marketplace prices may use different units than sector costs:

```xquery
let $outUnit := string(($m/Info/Pair[Key = "output-unit"]/Value)[1])
let $priceUnit := string(($m/Info/Pair[Key = "price-unit"]/Value)[1])
```

Always check marketplace `output-unit` and `price-unit` before using marketplace prices for revenue calculation.

## Unit Override Strategy

When a sector has incompatible units but revenue comparison is needed:

1. Check if the marketplace reports compatible units
2. Check if external data (e.g., statistical yearbook prices) is available
3. Apply explicit overrides only with documented justification:

```python
UNIT_OVERRIDES = {
    "coke": {"price_unit": "1975$/kg", "output_unit": "Mt"},
    "iron and steel": {"price_unit": "1975$/kg", "output_unit": "Mt"},
}
```

4. Document which overrides were applied in the analysis
