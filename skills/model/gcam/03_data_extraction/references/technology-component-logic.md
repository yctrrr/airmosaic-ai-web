# Technology Component Decomposition Logic

How sector costs are decomposed into technology-level components: energy, non-energy, capital, carbon, and residual.

## Why Component Decomposition

`sector/cost` is a single number per sector per year per region. But it aggregates contributions from multiple technologies with different cost structures. Component decomposition breaks the sector cost into:

- **Energy and material input costs**: costs from input fuels, feedstocks, electricity
- **Non-energy costs**: technology fixed and variable non-energy costs (from `globaltech_cost.csv`)
- **Capital and O&M**: capital and operations-related costs (where tracked)
- **Secondary output credits**: value offsets from secondary products
- **CO2 costs**: carbon price multiplied by emissions
- **Residual**: unexplained remainder after all tracked components

## Technology Cost Weighting

Technology costs are weighted by physical output to match the sector level:

```python
weighted_tech_cost = sum(tech_cost_i * output_proxy_i) / sum(output_proxy_i)
weighted_sector_cost = sector_cost * sum(output_proxy_i) / sum(all_output_i)
```

Where `output_proxy_i` is the physical output of technology `i` (from `output-primary/physical-output`).

## Component Categories

### Input Components (energy/materials)

For each `technology/input` node with `demand-physical`:

```python
component_cost = io_coefficient * component_unit_price * tech_output
```

- `io_coefficient`: input-output coefficient (e.g., GJ coal per ton cement)
- `component_unit_price`: price of the input good (from marketplace or upstream sector cost)
- `tech_output`: physical output of this technology

### Non-Energy Components

From `technology/StubTechCost` or equivalent:

- `non_energy_cost`: fixed + variable non-energy costs
- `capital_om_cost`: capital and O&M (where separated)

### Carbon Cost Components

```python
carbon_cost = co2_price * co2_emissions
```

Where:
- `co2_price` comes from `Marketplace/market[@name="ChinaCO2"]/price`
- `co2_emissions` comes from `technology/CO2-emissions` or calculated from input carbon content

### Secondary Credit

From `technology/output-secondary/physical-output`:

```python
secondary_credit = secondary_output * secondary_price
```

This offsets sector cost (negative value).

### Residual

```python
residual = weighted_tech_cost - sum(all_tracked_components)
```

A large residual indicates untracked cost elements or weighting mismatch.

## Generic vs Transport Methods

### Generic Method

Used for most industrial sectors (cement, iron and steel, ammonia, etc.):

1. Iterate over `technology/input` nodes
2. Look up input prices from marketplace or upstream sectors
3. Calculate component costs from coefficients * prices * output
4. Sum non-energy, energy, carbon, secondary

### Transport Method

Transport sectors use `TranTechnology` nodes with different structure:

```python
# Transport uses load-factor and direct price paid
component_cost = load_factor * direct_price_paid * tech_output
```

Key differences:
- No `carbon_content` field
- Uses `load_factor` and `direct_price_paid` instead of `io_coefficient` and `component_price`
- Technology cost formulas differ from industrial sectors

## Upstream Cost Lookup

For energy input prices, the decomposition looks up:

1. **Marketplace prices**: `Marketplace/market/price` for the input fuel/good
2. **Upstream sector cost**: If no marketplace price is found, use the producing sector's `sector/cost`
3. **Fallback**: Mark price source as `not_found`

The lookup is recursive: if sector A uses input from sector B, and sector B's price comes from marketplace, the decomposition traces this chain.

## Quality Assessment

After decomposition, assess quality:

| Quality | Condition |
|---------|-----------|
| `good` | Residual < 10% of weighted_tech_cost |
| `acceptable` | Residual < 25% |
| `poor` | Residual >= 25% or missing major components |

Large residuals suggest:
- Missing input price data
- Technology not covered by the decomposition method
- Weighting mismatch between technology sample and full sector
- Secondary output not properly credited

## Key Relationship

```
weighted_tech_cost ≈ energy_material + non_energy + capital_om + co2_cost + secondary_credit + residual
weighted_sector_cost ≈ sum of all technology contributions reweighted to sector level
```

`weighted_sector_cost` may differ from `selected_unit_price` because:
- It uses the component technology sample as weights
- Not all technologies in the sector may have been decomposed
- The sector cost applies to the full sector, not just decomposed technologies
