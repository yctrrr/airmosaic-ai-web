# XQuery Patterns: Price and Quantity

## Market Rows

Market rows represent GCAM Marketplace transactions. Each market has a price and supply quantity:

```xquery
for $s in collection()/scenario[@name = "{scenario}"]
for $m in $s/world/Marketplace/market[number(@year) = $years
  and string(MarketRegion) = $regions
  and string(MarketGoodOrFuel) = $sectors]
let $outUnit := string(($m/Info/Pair[Key = "output-unit"]/Value)[1])
let $priceUnit := string(($m/Info/Pair[Key = "price-unit"]/Value)[1])
return string-join((
  string($s/@name), "marketplace", string($m/MarketRegion),
  string($m/MarketGoodOrFuel), string($m/@year),
  string($m/price), string($m/supply),
  $outUnit, $priceUnit
), "	")
```

## Sector Cost Rows

Sector cost represents the department-level service price:

```xquery
for $s in collection()/scenario[@name = "{scenario}"]
for $r in $s/world/*[@type = "region" and string(@name) = $regions]
for $sec in $r/*[@type = "sector" and string(@name) = $sectors]
for $cost in $sec/cost[number(@year) = $years]
let $quantity := string(sum($sec//*[@type = "output"]/physical-output[@vintage = $cost/@year]/number(.)))
let $outUnit := string((
  $sec//*[@type = "output"]/physical-output[@vintage = $cost/@year]/@unit,
  $sec//*[@type = "output"]/physical-output/@unit
)[1])
where string($cost) != ""
return string-join((
  string($s/@name), "sector_cost", string($r/@name),
  string($sec/@name), string($cost/@year),
  string($cost), $quantity, $outUnit
), "	")
```

## Key Fields

| Field | Source | Meaning |
|-------|--------|---------|
| `scenario` | `$s/@name` | scenario identifier |
| `source` | "marketplace" or "sector_cost" | origin of the row |
| `region` | region name | province or China aggregate |
| `sector` | sector/market name | what is being measured |
| `year` | `@year` or `@vintage` | model year |
| `price` | `cost/text()` or `price/text()` | unit price in model units |
| `quantity` | sum of `physical-output` | physical output in model units |
| `output_unit` | from `output-unit` | unit of physical output |
| `price_unit` | from `price-unit` or marketplace info | unit of price |

## Aggregation

Province-level rows can be aggregated by computing weighted prices:

```python
weighted_price = sum(price_i * quantity_i) / sum(quantity_i)
```

Or for China-reported (non-provincial) rows, use the value directly.

National total quantity = sum of all province quantities.
