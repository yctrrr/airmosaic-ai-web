# GCAM Input Data Processing Chain

## Overview

GCAM input data flows through a multi-step pipeline before becoming model output:

```text
Raw CSV data
  -> R processing scripts (gcamdata package)
  -> Intermediate R data objects
  -> XML generation scripts
  -> Model input XML files
  -> GCAM solver (C++)
  -> BaseX output database
  -> XQuery extraction
```

## Example: Detailed Industry Sector Chain

### Step 1: Raw Data

```text
input/gcamdata/inst/extdata/gcam-china/
  detailed_industry_output.csv    (historical province output, Mt)
  IO_detailed_industry.csv        (input-output coefficients)
  A323.sector.csv                 (sector metadata: units, logit, etc.)
  A323.globaltech_cost.csv        (technology non-energy costs)
  A323.efficiency_improve.csv     (efficiency improvement rates)
```

### Step 2: R Processing

```text
input/gcamdata/R/
  zgcamchina_L1323.Detailed_industry.R       (process output and IO)
  zgcamchina_L2323.Detailed_industry_CHINA.R (build TechCost, ShareWeights)
  zgcamchina_xml_Detailed_industry_CHINA.R   (write XML)
```

### Step 3: Generated XML

```text
input/gcamdata/xml/detailed_industry_CHINA.xml
```

### Step 4: Model Output (BaseX)

Queryable via XPath/XQuery:
```text
collection()/scenario/world/*[@type="region"]/*[@type="sector"]
  /cost                       (sector service price)
  //physical-output           (sector physical output)
  //demand-physical           (input demand)
```

## Key Principle: Input != Output

The sector cost in BaseX output is NOT a copy of any input CSV value. It is the model-solved result, influenced by:

1. Technology non-energy costs from `A323.globaltech_cost.csv`
2. Energy input prices (set by energy market equilibrium)
3. Input coefficients (from `IO_detailed_industry.csv`)
4. Carbon prices and CCS costs
5. Technology share-weight competition
6. Service demand response to price and income

Even if all technology input costs are constant over time, `sector/cost` still varies across years and provinces because energy prices, carbon prices, and technology shares change.

## Province-Level Tracing Example: Cement Sector Cost in AH

To trace a specific output value (e.g., `sector/cost` for cement in Anhui in 2030):

1. **Identify input CSV**: The cement sector's base costs come from `gcam-china/A323.globaltech_cost.csv`
2. **Find R processing**: `zgcamchina_L2323.Detailed_industry_CHINA.R` reads this CSV and generates `StubTechCost` nodes
3. **Find generated XML**: `detailed_industry_CHINA.xml` contains `<region name="AH"><supplysector name="cement">...`
4. **Trace energy inputs**: Cement's `IO_detailed_industry.csv` defines how much coal, electricity, etc. each ton of cement uses
5. **Trace energy prices**: Coal price comes from the coal market equilibrium; electricity price from the power sector solution
6. **Check carbon price**: If a CO2 policy is active, `Marketplace/market[@name="ChinaCO2"]/price` adds to sector cost
7. **Check technology mix**: In 2030, CCS technology share-weights determine whether `cement` or `cement CCS` dominates, affecting average cost

The final `sector/cost` integrates all these factors through the GCAM solver.

## Parameter Inventory Approach

A systematic approach for any sector:

1. Identify the sector in the catalog tables (`A323.sector_China.csv`)
2. Note `output-unit` and `price-unit` — these determine how to interpret output values
3. Find the R processing script that handles this sector
4. Trace which input CSVs the script reads
5. Check which parameters vary over time vs. are constant
6. Verify generated XML contains expected nodes
7. Understand which model mechanisms affect the final solved value

## Differences Between GCAM-Core and GCAM-China

GCAM-Core (`JGCRI/gcam-core`) and GCAM-China (`umd-cgs/gcam-china`) have different sector configurations. For example:

- GCAM-Core `A323.sector.csv`: `iron and steel` with `price-unit=1975$/kg`
- GCAM-China `A323.sector_China.csv`: `iron and steel` with `price-unit=1975$/GJ`

Always check the local configuration files rather than assuming GCAM-Core defaults apply to GCAM-China. See `../references/gcam-china-vs-official.md` for the full comparison.
