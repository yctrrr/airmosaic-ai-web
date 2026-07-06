# Province and Region Mapping

GCAM-China province codes, the China aggregate node, and how to map between GCAM regions and real-world geography.

## Province Code Table

GCAM-China uses two-letter abbreviations for 31 Chinese provinces/regions:

| Code | Province | Code | Province |
|------|----------|------|----------|
| AH | Anhui | LN | Liaoning |
| BJ | Beijing | NM | Inner Mongolia |
| CQ | Chongqing | NX | Ningxia |
| FJ | Fujian | QH | Qinghai |
| GD | Guangdong | SC | Sichuan |
| GS | Gansu | SD | Shandong |
| GX | Guangxi | SH | Shanghai |
| GZ | Guizhou | SN | Shaanxi |
| HA | Henan | SX | Shanxi |
| HB | Hubei | TJ | Tianjin |
| HE | Hebei | XJ | Xinjiang |
| HI | Hainan | XZ | Tibet |
| HL | Heilongjiang | YN | Yunnan |
| HN | Hunan | ZJ | Zhejiang |
| JL | Jilin |  |  |
| JS | Jiangxi |  |  |

## China Aggregate Node

`China` is NOT a province — it is the national aggregate region. It contains:

- National-level `supplysector` and `pass-through-sector` nodes
- National energy distribution pass-throughs
- National account and demographics
- Some national-level sector cost rows

### When to use China vs Province nodes

| Task | Use |
|------|-----|
| Province-level sector cost | Province nodes (AH, BJ, ...) |
| Provincial production output | Province nodes |
| National energy pass-through | China node |
| Cross-province aggregation | Sum over all 31 provinces |
| China-reported values | China node (but verify if province aggregation is more appropriate) |

## Province Code Mapping File

Location: `database_R/Prov_code_china.csv`

Columns:
- `Province_code`: Numeric code (e.g., 34 for Anhui)
- `EN_name`: English name (e.g., `Anhui`)
- `GCAM_name`: GCAM abbreviation (e.g., `AH`)
- Possibly `CH_name`: Chinese name

Query pattern:
```xquery
collection()/scenario/world/*[@type="region" and @name="AH"]
```

## All Province Query Pattern

To query all 31 provinces at once:

```xquery
let $regions := ("AH","BJ","CQ","FJ","GS","GD","GX","GZ","HI","HE","HL","HA",
                 "HB","HN","NM","JS","JX","JL","LN","NX","QH","SN","SD","SH",
                 "SX","SC","TJ","XZ","XJ","YN","ZJ")
for $r in $s/world/*[@type="region" and string(@name) = $regions]
```

Or, to query all regions including China:

```xquery
for $r in $s/world/*[@type="region"]
```

But be careful: this includes non-China regions if the scenario has global scope.

## Province Availability

Not all sectors exist in all provinces. For example:
- `aluminum` may only exist in a few provinces
- `paper` and `food processing` may only have national-level definitions in some GCAM-China versions
- Some resource sectors like `coal` or `natural gas` exist only in producing provinces

Always verify with:

```xquery
distinct-values(
  for $r in collection()/scenario/world/*[@type="region" and @name = $regions]
  where $r/*[@type="sector" and @name = $sector]
  return string($r/@name)
)
```

## Aggregation: Province to National

To get national totals from province data:

- **Quantity**: Sum province values directly
- **Price**: Compute quantity-weighted average:

```python
national_price = sum(price_i * quantity_i) / sum(quantity_i)
```

Do NOT simply average province prices — this ignores that larger provinces produce more.

## Region Node Types

Under each region, common child types include:

| @type | Description |
|-------|-------------|
| `region` | Sub-region (unusual in GCAM-China) |
| `sector` | Supply sector or pass-through sector |
| `resource` | Conventional resource |
| `renewresource` | Renewable resource |
| `unlimited-resource` | Unlimited resource |
| `energy-final-demand` | Final energy demand |
| `gcam-consumer` | Consumer node |
| `demographics` | Population |
| `nationalAccount` | National GDP and accounts |
