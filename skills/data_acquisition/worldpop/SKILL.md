---
name: worldpop
description: Discover, download, organize, and validate WorldPop gridded population data from official WorldPop APIs and data files. Use when an external agent or analyst needs population rasters by country, year, sex, age group, UN-adjusted/unadjusted product, constrained/unconstrained product, or WorldPop zonal/statistical services for exposure weighting and health burden workflows.
---

# WorldPop Data Acquisition

## Purpose

Use this skill to acquire WorldPop population products on demand for AirMosaic AI. Download only requested countries, years, and products. Keep raster files and derived tables in the local workspace, not in GitHub.

## Official Interfaces

- Data catalog/download discovery: `https://www.worldpop.org/rest/data`
- Spatial services and stats API: `https://api.worldpop.org/v1/services`
- Data file host commonly returned by metadata: `https://data.worldpop.org`

WorldPop documents an API rate limit. Cache metadata and downloaded files locally rather than repeatedly querying the same products.

## Default Local Cache

```text
${AIRMOSAIC_LOCAL_WORKSPACE}/data_cache/worldpop
```

Suggested layout:

```text
worldpop/
  raw/
    <iso3>/
      <project>/
        <year>/
  metadata/
  derived/
```

## Discover And Download

Use the bundled script for metadata discovery and optional download:

```powershell
$env:AIRMOSAIC_LOCAL_WORKSPACE = "D:\AirMosaicAI\local_workspace"

python ".\scripts\download_worldpop.py" `
  --project "wpgp" `
  --iso3 "CHN" `
  --year 2020 `
  --root "$env:AIRMOSAIC_LOCAL_WORKSPACE\data_cache\worldpop" `
  --download
```

The script writes metadata JSON/CSV to `metadata/` and downloads matching files under `raw/<iso3>/<project>/<year>/`.

## Agent Contract

External agents should call a wrapper such as `acquire_worldpop_population`. The wrapper should validate:

- `iso3` country code;
- project/product alias;
- year range;
- whether download or metadata-only discovery is requested;
- output root stays under `${AIRMOSAIC_LOCAL_WORKSPACE}`.

Agents should not receive unrestricted local paths or write access outside the configured cache root.

## Product Selection Notes

Use exact WorldPop project/product names when known. For ambiguous requests, first run metadata discovery and inspect product titles, file names, years, and resolution before downloading.

Population discovery uses project aliases under the `pop` API group, for example `wpgp` for Global per country 2000-2020.

Typical filtering dimensions:

- country ISO3 code;
- product/project alias;
- year;
- file extension such as `.tif`, `.tiff`, `.zip`, `.csv`;
- sex/age-specific wording in `title`, `data_file`, or metadata fields;
- UN-adjusted versus unadjusted product wording;
- constrained versus unconstrained product wording.

## Validation Checklist

- Confirm files are non-empty and match expected extension.
- Preserve metadata sidecars next to downloaded files.
- Record WorldPop project/product alias, country, year, and download URL.
- Do not unzip or resample rasters unless the caller requests it.
- Do not commit raw rasters, derived rasters, cache manifests, or local paths to GitHub.

## References

- `references/worldpop-api.md`: API endpoint notes and metadata fields.
- `references/privacy-redaction-rules.md`: sanitization checklist.
