# SSP-RCP Scenario Setup

## Overview

GCAM scenarios combine Shared Socioeconomic Pathways (SSPs) with Representative Concentration Pathways (RCPs) or policy targets. In GCAM-China, the DPEC (Dynamic Projection of Emissions in China) framework standardizes these combinations.

## Typical Scenario Names

| Scenario Name | Meaning |
|---------------|---------|
| `DPEC_SSP1` | SSP1 baseline (no additional policy) |
| `DPEC_SSP2` | SSP2 baseline |
| `DPEC_SSP3` | SSP3 baseline |
| `DPEC_SSP4` | SSP4 baseline |
| `DPEC_SSP5` | SSP5 baseline |
| `DPEC_SSP1_Peak2030_NDC2035` | SSP1 with peak 2030 and NDC 2035 |
| `DPEC_SSP1_Peak2030_NDC2035_NZ2060` | SSP1 with peak 2030, NDC 2035, and net-zero 2060 |

## How Scenarios Are Built

Each scenario has a configuration XML that lists its components. The differences between scenarios come from:

1. **Different SSP assumptions**: GDP, population, technology cost trajectories
2. **Different emission constraints**: carbon budget, emission caps
3. **Different policy components**: CCS share weights, renewable mandates, carbon prices

For example, `DPEC_SSP1` loads SSP1 socioeconomic data and standard technology assumptions, while `DPEC_SSP1_Peak2030_NDC2035` adds emission constraints and possibly different share-weight files.

## Running Scenarios

Scenarios are run by passing the configuration file to the GCAM executable. In the release package:

```bat
rem Run SSP1 baseline
gcam.exe -C configuration_china_ssp1.xml

rem Run DPEC scenario
gcam.exe -C DPEC\configuration_dpec_ssp1_19.xml
```

Results go to `output/<scenario_name>/`.

## Output Database

Each scenario creates a BaseX database at:
```text
output/<scenario_name>/database_basexdb/
```

This is what the data extraction layer queries. The database name `database_basexdb` is the default used by both the release package and the `rgcam` R package.

## Key References

- SSP Database: https://tntcat.iiasa.ac.at/SspDb/
- GCAM Documentation: https://jgcri.github.io/gcam-doc/
- GCAM-China GitHub: https://github.com/umd-cgs/gcam-china
