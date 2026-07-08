# Data Requirements for PM2.5 Health Impact Analysis

## Overview

Five data components are required. All must share the same spatial resolution.

## 1. PM2.5 Concentration Grid

**Schema**: X_Lon, Y_Lat, concentration

| Field | Type | Description |
|---|---|---|
| X_Lon | numeric | Grid centroid longitude (decimal degrees) |
| Y_Lat | numeric | Grid centroid latitude (decimal degrees) |
| concentration | numeric | Annual mean PM2.5 (ug/m3) |

**Resolution**: Typically 0.1 degree (~11 km at equator)

**Source options**:
- TAP (Tsinghua University): 1 km → aggregated, China coverage
- Satellite-derived: MODIS/MISR/SeaWiFS AOD + GEOS-Chem simulation
- CAMS global reanalysis (0.75 deg, coarser)
- WRF-Chem or CMAQ model output

**Preprocessing notes**:
- Original 1 km grids must be aggregated to analysis resolution by taking the mean within each grid cell
- Concentration values should be capped at the RR curve maximum (default: 200 ug/m3)

## 2. Population Grid

**Schema**: X_Lon, Y_Lat, GridID, Year, urarea, Pop

| Field | Type | Description |
|---|---|---|
| X_Lon | numeric | Grid centroid longitude |
| Y_Lat | numeric | Grid centroid latitude |
| GridID | integer | Unique grid identifier |
| Year | integer | Data year |
| urarea | character | Urban/rural/overall classification |
| Pop | numeric | Total population count |

**Source options**:
- WorldPop: 100 m or 1 km, UN-adjusted, constrained/unconstrained
- GPW (Gridded Population of the World): ~1 km
- LandScan: ~1 km

**Preprocessing**: Must be aggregated to match the analysis resolution and spatially aligned with the concentration grid.

## 3. Age Structure Fractions

**Schema**: X_Lon, Y_Lat, GridID, Year, sex, agegroup, AgeStruc

| Field | Type | Description |
|---|---|---|
| X_Lon | numeric | Grid centroid longitude |
| Y_Lat | numeric | Grid centroid latitude |
| GridID | integer | Unique grid identifier |
| Year | integer | Data year |
| sex | character | 'male' or 'female' |
| agegroup | integer | Age group lower bound: 0, 5, 10, ..., 75, 80 |
| AgeStruc | numeric | Fraction of population in this age-sex group (0-1) |

**Constraints**:
- For each grid cell and sex, AgeStruc must sum to 1.0
- The 80 age group is the open-ended 80+ category
- WorldPop produces ages 0, 1, 5, 10, ..., 75, 80; the 1-year group is summed into 0-4

**Preprocessing**: Population counts by age-sex per grid cell are divided by total population to obtain fractions.

## 4. Baseline Mortality Rates

**Schema**: location_name, Year, metric, endpoint, sex, agegroup, MortRate

| Field | Type | Description |
|---|---|---|
| location_name | character | Location (e.g., 'China') |
| Year | integer | Data year |
| metric | character | Always 'Rate' |
| endpoint | character | Disease: 'copd', 'lc', 'lri', 'ihd', 'stroke' |
| sex | character | 'male' or 'female' |
| agegroup | integer | Age group: 0, 5, 10, ..., 75, 80, 85, 90, 95 |
| MortRate | numeric | Deaths per 100,000 population |

**Source**: GBD Results from IHME (vizhub.healthdata.org/gbd-results)

**Preprocessing notes**:
- Must be filtered to the target country and metric='Rate'
- If GBD data is not available for the target year, use the nearest available year
- 80+ sub-groups (80, 85, 90, 95) are summed before matching to WorldPop age structure

## 5. RR Curve Lookup Table

**Schema**: curve_name, endpoint, concentration, agegroup, RR

| Field | Type | Description |
|---|---|---|
| curve_name | character | 'GEMM-5COD' or 'IER' |
| endpoint | character | 'copd', 'lc', 'lri', 'ihd', 'stroke' |
| concentration | character | Rounded concentration for matching: '0', '0.1', ..., '200.0' |
| agegroup | integer | Age group: 0, 5, 10, ..., 75, 80 |
| RR | numeric | Relative risk at this concentration relative to TMREL |

**Constraints**:
- At concentration = 0 (TMREL), RR = 1.0 for all endpoints and ages
- Concentration values are rounded to 0.1 ug/m3 for exact matching
- For IER: agegroup is typically 25 (single curve for ages 25+)

**Derivation**: Obtained by running the GEMM or IER parameterized model against a sequence of concentrations. This format enables fast lookup in the grid calculation without re-running the CRF model at each grid cell.

## Resolution Alignment

All five components must share the same spatial resolution and coordinate system. The standard pipeline:

1. Define analysis grid from population data (0.1 degree centroids)
2. Aggregate PM2.5 to same grid by spatial mean
3. Match age structure fractions by GridID
4. Join baseline mortality and RR curves by endpoint/age/concentration (non-spatial join)
