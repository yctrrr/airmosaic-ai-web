# GCAM BaseX XML/XPath Structure

Based on a typical GCAM-China output database (`database_basexdb`).

## 1. Top Level

```text
collection()
  -> scenario
      @name: scenario identifier
      @date: run timestamp
      model-version: text value
      world:
        -> region
            @type = "region"
            @name = "AH" / "BJ" / ... / "China"
            supplysector or pass-through-sector
            resource / renewresource / unlimited-resource
            final-demand
            demographics
            nationalAccount
            gcam-consumer
```

The most common XPath start for exploratory queries:

```xquery
collection()/scenario/world/*[@type="region"]
```

To target only one province:

```xquery
collection()/scenario/world/*[@type="region" and @name="AH"]
```

To target the China aggregate node:

```xquery
collection()/scenario/world/*[@type="region" and @name="China"]
```

## 2. Main Child Nodes Under a Province Region

Chinese provinces are identified by `GCAM_name` from a province code mapping file. Typical region-level children:

| child_type     | xml_node              | description                                              |
| -------------- | --------------------- | -------------------------------------------------------- |
| `sector`       | `supplysector`        | main supply/demand sector; most commonly queried         |
| `sector`       | `pass-through-sector` | pass-through sector for intermediate energy distribution |
| `resource`     | `resource`            | conventional resource                                    |
| `resource`     | `renewresource`       | renewable resource                                       |
| `resource`     | `unlimited-resource`  | unlimited supply resource                                |
| `final-demand` | `energy-final-demand` | final energy demand                                      |
| (none)         | `demographics`        | population                                               |
| (none)         | `nationalAccount`     | national accounts / macro                                |
| (none)         | `gcam-consumer`       | consumer node                                            |

List all top-level sectors in province `AH`:

```xquery
for $s in collection()/scenario
for $sec in $s/world/*[@type="region" and @name="AH"]/*[@type="sector"]
return concat($s/@name, ",", $sec/@name)
```

## 3. Typical Sector Internal Structure

An industrial sector typically looks like:

```text
region
  -> sector / supplysector
      @type = "sector"
      @name = "cement" / "iron and steel" / ...
      cost:
          @year
          @unit
          text() = price or cost value
      -> subsector
          @type = "subsector"
          @name
          cost / share-weight / ...
          -> technology
              @type = "technology"
              @name
              -> output-primary or output
                  -> physical-output
                      @vintage
                      @unit
                      text() = physical output value
              -> input
                  -> demand-physical
                      @vintage
                      @unit
                      text() = physical input demand
```

Key points:

- Physical output is typically at `sector//output-primary/physical-output`
- Sector cost/price is typically at `sector/cost`
- Energy/material inputs are typically at `sector//input/demand-physical`

## 4. How sector/cost Is Formed

`sector/cost` in BaseX output is NOT a copy of any input CSV value. It is the model-solved sector service price or generalized cost, influenced by:

- **Technology non-energy input costs**: from `StubTechCost` or `input-cost` in XML, sourced from `globaltech_cost.csv`
- **Energy input prices and input coefficients**: energy prices from market equilibrium, coefficients from I/O tables or `globaltech_coef.csv`
- **Price elasticity feedback on demand**: higher prices reduce demand, which feeds back into sector cost
- **Carbon prices**: CO2 price from `Marketplace/market[@name="ChinaCO2"]` multiplied by emissions intensity
- **Secondary output value offsets**: secondary product revenue reduces net cost
- **Technology and subsector share-weights**: logit selection determines technology mix, which affects average cost
- **Market solution price feedback**: sector costs are part of the general equilibrium solution

**Consequence**: Even if all technology input costs are constant, `sector/cost` varies across years and provinces because energy prices, carbon prices, technology shares, and demand levels change. Do not expect `sector/cost` to match any single input CSV value.

## 5. Common Industrial Sector Sub-sector/Technology Examples

### cement
- subsector: cement
- technology: cement; cement CCS
- output: cement (unit: Mt)

### iron and steel
- subsector: BLASTFUR; EAF with DRI; EAF with scrap
- technology: Biomass-based; BLASTFUR; BLASTFUR CCS; EAF with DRI; EAF with DRI CCS; EAF with scrap; Hydrogen-based DRI
- output: iron and steel (unit: Mt)

### chemical
- subsector: chemical
- technology: chemical
- output: chemical (unit: EJ)

### other industry
- subsector: other industry
- technology: other industry
- output: other industry (unit: EJ)

### ammonia
- subsector: coal; gas; hydrogen; refined liquids
- technology: coal; coal CCS; gas; gas CCS; hydrogen; refined liquids
- output: ammonia (unit: Mt NH3)

Not all provinces have all sectors. For example, `aluminum`, `paper`, and `food processing` may exist at national level but not always at provincial level in some GCAM-China versions.

## 6. Province-Level Region Names

Province codes in GCAM-China are standard abbreviations: AH, BJ, CQ, FJ, GS, GD, GX, GZ, HI, HE, HL, HA, HB, HN, NM, JS, JX, JL, LN, NX, QH, SN, SD, SH, SX, SC, TJ, XZ, XJ, YN, ZJ.

The `China` node is the national aggregate, not a province. See `province-region-mapping.md` for the full mapping table and aggregation conventions.

## 7. Marketplace Structure

The Marketplace section records inter-sectoral transactions:

```text
scenario/world/Marketplace/
  -> market
      @type = "market"
      @name = "ChinaCO2" / sector-market names
      @year
      MarketRegion: region name
      MarketGoodOrFuel: good being traded
      price: equilibrium price
      supply: quantity supplied
      -> Info
          -> Pair[Key = "output-unit"]/Value
          -> Pair[Key = "price-unit"]/Value
```

Marketplace prices are equilibrium transaction prices, distinct from sector costs. For sectors where price-unit and output-unit are incompatible (e.g., iron and steel with `1975$/GJ` price and `Mt` output), marketplace prices may provide a more interpretable price signal — but always verify marketplace `price-unit` before use.
