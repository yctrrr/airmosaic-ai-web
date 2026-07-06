# GCAM Input Data Architecture

The complete pipeline from raw data to queriable output, so agents understand where values originate and how to trace them.

## Pipeline Overview

```
Raw CSV data (inst/extdata/)
  -> R processing scripts (gcamdata/R/)
  -> Generated XML (gcamdata/xml/)
  -> GCAM C++ solver
  -> BaseX XML output database (output/<scenario>/database_basexdb/)
  -> XQuery extraction (this skill)
```

## Layer 1: Raw Input Data

Location: `input/gcamdata/inst/extdata/`

These CSVs contain the empirical data and assumptions fed into the model. Key subdirectories:

| Directory | Content |
|-----------|---------|
| `gcam-china/` | China-specific sector definitions, province data, I/O tables |
| `energy/` | Energy sector technology costs, efficiencies, resource curves |
| `emissions/` | Emission factors, control costs |
| `socioeconomics/` | GDP, population, SSP projections |
| `aglu/` | Agriculture and land use data |

### Critical Files for Industry Sectors

| File | Content |
|------|---------|
| `gcam-china/A323.sector_China.csv` | Sector metadata: names, output-unit, price-unit, logit exponent |
| `gcam-china/A323.subsector.csv` | Subsector definitions |
| `gcam-china/A323.globaltech_cost.csv` | Technology non-energy costs |
| `gcam-china/A323.globaltech_coef.csv` | Input-output coefficients (GJ input per ton output) |
| `gcam-china/A323.efficiency_improve.csv` | Efficiency improvement rates over time |
| `gcam-china/detailed_industry_output.csv` | Historical province-level industrial output (Mt) |
| `gcam-china/IO_detailed_industry.csv` | Province-level input-output tables |

## Layer 2: R Processing Scripts

Location: `input/gcamdata/R/`

Script naming convention: `zgcamchina_L{level}{number}.{description}.R`

- `L1xxx`: Level 1 — read and process raw data
- `L2xxx`: Level 2 — calibrate parameters, build technology cost/share-weight/coef structures
- `zgcamchina_xml_*.R`: Convert processed data to XML format

### Example: Detailed Industry Chain

```
zgcamchina_L1323.Detailed_industry.R     -> reads output, I/O, sector CSV
zgcamchina_L2323.Detailed_industry_CHINA.R -> builds TechCost, ShareWeights, Coefs
zgcamchina_xml_Detailed_industry_CHINA.R   -> writes detailed_industry_CHINA.xml
```

## Layer 3: Generated XML

Location: `input/gcamdata/xml/`

These are the XML files read by the GCAM solver. Each file typically represents one scenario component.

### Key XML Files for GCAM-China

| File | Content |
|------|---------|
| `detailed_industry_CHINA.xml` | All detailed industry sectors by province |
| `cement_CHINA.xml` | Cement sector |
| `Fert_CHINA.xml` | Ammonia / nitrogen fertilizer sector |
| `CCS_shrwt_CHINA.xml` | CCS technology share weights |
| `Cstorage_CHINA.xml` | Carbon storage resource supply curves |
| `no_offshore_ccs.xml` | Disable offshore CCS |
| `turn_off_ccs.xml` | Global CCS disable switch |

## Layer 4: GCAM Solver

The solver (C++ binary) reads the configuration XML, loads all component XMLs, and solves the partial equilibrium system for each time period. Output is written as XML to a BaseX database.

## Layer 5: BaseX Output

Location: `output/<scenario>/database_basexdb/`

This is what XQuery queries. The database contains the full model state: all regions, sectors, technologies, costs, outputs, inputs, and marketplace transactions.

## Critical Insight: Input != Output

`sector/cost` in BaseX output is NOT a value from any input CSV. It is the model-solved result, influenced by:

1. Technology non-energy costs (from `globaltech_cost.csv`)
2. Energy input prices (from energy market equilibrium)
3. Input coefficients (from `globaltech_coef.csv` or I/O tables)
4. Carbon prices (from carbon market or policy)
5. Technology share-weight competition (logit selection)
6. Service demand response to price and income

Even when input costs are constant, `sector/cost` varies across years and provinces because energy prices, carbon prices, and technology shares change.

## Tracing a Parameter End-to-End

To trace where a specific output value comes from:

1. Identify the sector in `A323.sector_China.csv` (output-unit, price-unit)
2. Find the R processing script that builds this sector's XML
3. Identify which input CSVs the script reads
4. Check which parameters vary over time vs. are constant
5. Understand which model mechanisms affect the final solved value
