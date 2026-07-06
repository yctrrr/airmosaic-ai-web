# XQuery Patterns: Technology Inputs and Components

## Generic Technology Components

For most industrial sectors, technology components are extracted from technology-level input, output, and cost nodes:

```xquery
for $s in collection()/scenario[@name = "{scenario}"]
for $r in $s/world/*[@type = "region" and string(@name) = $regions]
for $sec in $r/*[@type = "sector" and string(@name) = $sectors]
for $sub in $sec/*[@type = "subsector"]
for $tech in $sub/*[@type = "technology"]
let $year := number($tech/@year)
let $secCost := string(($sec/cost[number(@year) = $year])[1])
let $techCost := string(($tech/cost[number(@year) = $year])[1])
let $techOutput := sum($tech/*[@type = "output"]/physical-output[@vintage = $year]/number(.))
where $year = $years and $techOutput > 0
return ...
```

## Component Types

Each technology row is decomposed into component types:

| component_type | meaning | source |
|----------------|---------|--------|
| `input` | energy or material input | `technology/input` |
| `secondary_output_credit` | secondary output value offset | `technology/output-secondary` |
| `no_component` | technology with no inputs | technology leaf |

## Component Fields

| field | meaning |
|-------|---------|
| `io_coefficient` | input-output coefficient |
| `demand_physical` | physical input demand |
| `component_price` | input price (marketplace or sector cost lookup) |
| `component_price_source` | where the price was found |
| `carbon_content` | carbon content per unit input |
| `secondary_physical_output` | secondary output quantity |

## Transport Technology Components

Transport uses a different formula with `load-factor` and `direct_price_paid`:

- Uses `TranTechnology` nodes instead of generic `technology`
- Includes `load_factor` and `direct_price_paid` fields
- Does not include `carbon_content`

## Weighted Aggregation

After extracting components, aggregate by scenario, region, sector, and year using `output_proxy` (physical output or input-derived proxy) as weights:

```python
weighted_cost = sum(tech_cost_i * output_proxy_i) / sum(output_proxy_i)
```

This produces component summaries:
- `energy_material_cost`
- `non_energy_cost`
- `capital_om_cost`
- `secondary_credit`
- `reported_co2_cost`
- `residual_after_reported_co2`
