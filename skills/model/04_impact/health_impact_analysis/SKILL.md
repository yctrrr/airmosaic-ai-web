---
name: health-impact-analysis
description: Calculate and visualize PM2.5-attributable premature deaths using grid-level Population Attributable Fraction (PAF) methodology. Supports GEMM-5COD and IER concentration-response curves with GBD baseline mortality. Use when an agent or analyst needs to estimate health burden from air pollution exposure at sub-national resolution.
---

# PM2.5 Health Impact Analysis

## Purpose

Estimate PM2.5-attributable premature mortality at grid resolution using the standard environmental epidemiology Population Attributable Fraction (PAF) framework. This skill covers the full pipeline from exposure-population-mortality integration through visualization.

## Methodology

### Core Formula

The health impact is calculated per grid cell using the standard PAF approach:

`
Attributable Deaths = Population x PAF Mortality Rate

PAF Mortality Rate = sum over (endpoint, sex, age):
    AgeStruc(age, sex) x BaselineMortRate(endpoint, sex, age) x PAF(conc, endpoint, age)

PAF(conc, endpoint, age) = (RR(conc, endpoint, age) - 1) / RR(conc, endpoint, age) / 100,000
`

Where:
- **RR** = Relative Risk from concentration-response curve (GEMM-5COD or IER)
- **BaselineMortRate** = GBD cause-specific mortality rate per 100,000 population
- **AgeStruc** = fraction of population in each age-sex group
- **concentration** = annual mean PM2.5 (ug/m3), capped at the RR curve maximum

### Concentration-Response Curves

Two standard curves are supported:

| Curve | Full Name | Source | Endpoints |
|---|---|---|---|
| GEMM-5COD | Global Exposure Mortality Model, 5 Causes of Death | Burnett et al. (2018, 2022) | COPD, LC, LRI, IHD, Stroke |
| IER | Integrated Exposure-Response | GBD 2010/2013 | COPD, LC, LRI, IHD, Stroke |

RR values are stored in a lookup table with columns:
curve_name, endpoint, concentration, agegroup, RR

Concentrations are binned at 0.1 ug/m3 resolution. Values above the maximum curve concentration are capped.

### Age Group Handling

- Standard GBD 5-year age groups: 0, 5, 10, ..., 75, 80+
- For 80+ (open-ended group): WorldPop keeps 80 as the single 80+ bin. GBD mortality for 85, 90, 95 sub-groups is summed into the 80+ age structure before PAF calculation.

## Required Input Data

### 1. PM2.5 Concentration Grid
- Format: CSV with columns X_Lon, Y_Lat, concentration
- Resolution: analysis resolution (e.g., 0.1 degree)
- Unit: ug/m3 annual mean
- Source examples: TAP, satellite-derived (MODIS/MISR/SeaWiFS), chemical transport model output

### 2. Population Grid
- Format: RDS or CSV with columns X_Lon, Y_Lat, GridID, Year, urarea, Pop
- Resolution: must match concentration grid
- Source examples: WorldPop, GPW, LandScan

### 3. Age Structure Fractions
- Format: RDS or CSV with columns X_Lon, Y_Lat, GridID, Year, sex, agegroup, AgeStruc
- Each grid cell's age fractions must sum to 1 per sex
- Source: derived from WorldPop age-sex population products

### 4. Baseline Mortality Rates
- Format: CSV with columns location_name, Year, metric, endpoint, sex, agegroup, MortRate
- Unit: deaths per 100,000 population
- Source: GBD Results (IHME), national or subnational

### 5. RR Curve Lookup Table
- Format: CSV with columns curve_name, endpoint, concentration, agegroup, RR
- Concentration values as character (rounded to 0.1 for matching)
- RR = 1.0 at theoretical minimum risk exposure level (TMREL = 0 ug/m3)

## Output

### Grid-Level Results
pm25_premature_death_grid_{curve}_{year}.csv

| Column | Description |
|---|---|
| X_Lon, Y_Lat | Grid centroid coordinates |
| GridID | Unique grid identifier |
| Year | Data year |
| urarea | Urban/rural/overall classification |
| Pop | Population count |
| curve_name | RR curve used |
| concentration | PM2.5 concentration (ug/m3) |
| MortRate_PM25 | PAF-attributable mortality rate |
| Mort | Attributable premature deaths |

### Summary Statistics
pm25_premature_death_summary_{curve}_{year}.csv

Aggregated by Year, curve_name, urarea:
- Total population, total deaths, population-weighted mean concentration

### Visualization
- Grid map of Mort values, binned: <1, 1-5, 5-10, 10-25, 25-50, 50-75, 75-100, 100-150, >150
- Spectral color palette (reversed), units: deaths per grid cell
- China boundary overlay with South China Sea inset

## Agent Contract

External agents should call a wrapper that validates:
- Year(s) to process
- RR curve selection (GEMM-5COD or IER)
- Input data paths for all five required components
- Output directory (must stay within workspace)
- Whether to run calculation, visualization, or both

Agents should not receive unrestricted filesystem access. Output paths must be scoped to the configured workspace.

## Configuration

Controlled via environment variables or config file:
- PM25_DEATH_YEARS: comma-separated years (default: 2023)
- PM25_DEATH_CURVE: curve name (default: GEMM-5COD)
- Input path overrides for each data component

## References

- 
eferences/methodology.md: Full PAF derivation, GEMM vs IER comparison, uncertainty considerations
- 
eferences/data_requirements.md: Detailed data specifications, expected schemas, preprocessing notes

## Templates

- 	emplates/calculate_pm25_deaths.R: Generalized grid-level PAF death calculation
- 	emplates/visualize_pm25_deaths.R: Generalized mortality map generation

## Examples

- examples/workflow_pm25_hia.R: End-to-end example from data loading through visualization
