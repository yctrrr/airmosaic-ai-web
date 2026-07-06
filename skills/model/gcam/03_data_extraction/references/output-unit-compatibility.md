# Output Unit Compatibility

## Problem

GCAM sector output uses two independent unit fields: `price-unit` for `sector/cost` and `output-unit` for `physical-output`. Direct multiplication only produces a meaningful monetary proxy when the two units are compatible.

## Compatibility Matrix

| Scenario | Price Unit | Output Unit | Compatible? |
|----------|-----------|-------------|-------------|
| Both mass/commodity | `1975$/kg` | `Mt` | Yes: Mt->kg conversion |
| Both energy | `1975$/GJ` | `EJ` | Yes: EJ->GJ (service proxy) |
| Mixed | `1975$/GJ` | `Mt` | **No**: different physical dimensions |

## Handling Incompatible Units

When units are incompatible (e.g. iron and steel in some GCAM-China configs):

1. Mark the row as `incompatible_or_unknown`
2. Do not calculate `cost * output` as revenue
3. Investigate the input configuration to determine if `price-unit` should be changed
4. If external price data is available, use that instead of GCAM `sector/cost`

## Common Unit Override Patterns

Some sectors need explicit unit overrides because the model input configuration assigns energy-based price units to mass-output sectors:

```python
UNIT_OVERRIDES = {
    "coke": {"price_unit": "1975$/kg", "output_unit": "Mt"},
    "iron and steel": {"price_unit": "1975$/kg", "output_unit": "Mt"},
}
```

Apply overrides before computing revenue proxies, and document which overrides were applied.
