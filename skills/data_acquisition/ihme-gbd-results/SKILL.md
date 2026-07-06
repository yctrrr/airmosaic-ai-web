---
name: ihme-gbd-results
description: Fetch and process IHME GBD Results data from vizhub.healthdata.org through a user-authenticated browser session. Use when an external agent or analyst needs GBD mortality, population, cause, age, sex, location, measure, metric, or year data and direct API/download requests are blocked, rate-limited, or need to match IHME web UI output schemas.
---

# IHME GBD Results

## Purpose

Use this skill for IHME GBD Results acquisition and local processing. The skill does not store credentials, cookies, tokens, browser profiles, or personal paths. Raw exports and processed mortality tables must stay under the AirMosaic local workspace.

## Local Cache Boundary

Default local-only cache:

```text
${AIRMOSAIC_LOCAL_WORKSPACE}/data_cache/gbd_health
```

Do not commit raw IHME exports, processed health tables, cookies, browser profiles, or login artifacts to GitHub.

## Workflow

1. Open `https://vizhub.healthdata.org/gbd-results/` in a Chromium browser with remote debugging enabled.
2. Let the user log in and complete any verification manually.
3. Prefer the page's own search flow over direct `fetch` or `requests` calls. Direct calls to internal PHP endpoints can be blocked or return stale/error state.
4. Use `scripts/fetch_gbd_results_redux.py` to drive the loaded page's Redux store and collect `tableData`.
5. Save raw IHME output separately from project-specific processed outputs.
6. Map IHME display names to local schemas explicitly; do not infer endpoint or age mappings from sort order alone.
7. Validate every processed output against raw IHME rows by key columns and numeric values.

## Browser Setup

Use a user-chosen temporary profile path. Do not write personal profile paths into reusable scripts or docs.

```powershell
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$profile = "$env:TEMP\airmosaic-gbd-browser-profile"
Start-Process -FilePath $chrome -ArgumentList @(
  "--remote-debugging-port=9222",
  "--remote-allow-origins=*",
  "--user-data-dir=$profile",
  "--no-first-run",
  "--no-default-browser-check",
  "https://vizhub.healthdata.org/gbd-results/"
)
```

## Fetch Command

```powershell
$env:AIRMOSAIC_LOCAL_WORKSPACE = "D:\AirMosaicAI\local_workspace"
$out = "$env:AIRMOSAIC_LOCAL_WORKSPACE\data_cache\gbd_health\raw\gbd_2019_2023_mortality_rate.csv"

python ".\scripts\fetch_gbd_results_redux.py" `
  --out $out `
  --years 2019,2020,2021,2022,2023 `
  --locations 1,6,101,102 `
  --causes 426,493,322,494,976,509,409 `
  --ages 1,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,30,31,32,235 `
  --sexes 1,2 `
  --measures 1 `
  --metrics 3 `
  --port 9222
```

The script writes:

- output CSV;
- JSON sidecar with parameters, returned row count, and error state.

If the sidecar contains an error such as `ERROR_NO_RESULTS`, do not trust stale rows left in the browser table.

## Common IDs

- GBD 2023 version: `8352`
- Context: `cause`
- Population group: `1`
- Measure deaths: `1`
- Metric rate: `3`
- Example locations: `1` Global, `6` China, `101` Canada, `102` United States of America
- Sexes: `1` Male, `2` Female

Cause IDs used in the AirMosaic mortality workflow:

- `426` Tracheal, bronchus, and lung cancer
- `493` Ischemic heart disease
- `322` Lower respiratory infections
- `494` Stroke
- `976` Diabetes mellitus type 2
- `509` Chronic obstructive pulmonary disease
- `409` Non-communicable diseases
- `294` All causes
- `956` Respiratory infections and tuberculosis
- `491` Cardiovascular diseases

Age IDs:

- Standard mortality ages: `1,6:20,30,31,32,235`, mapping to `0,5,...,95`.
- GEMM-style ages: `1,6:20,21`, mapping to `0,5,...,80`.

## Processing Rules

Keep project-specific processing in local project code, not in this skill. Recommended pattern:

1. Keep historical rows only through the last trustworthy year.
2. Use real GBD rows for newly available years.
3. Preserve existing output schemas exactly unless the caller requests a schema change.
4. If GBD omits low-age cause combinations, leave them absent or fill only with a documented method.
5. Write a missing-combination report and provenance summary separately from the main table.

## Agent Contract

External agents should call a controlled wrapper such as `fetch_gbd_results`. The wrapper should validate requested year, location, cause, age, sex, measure, and metric IDs, then invoke the script against a user-authenticated browser session.

The agent must not receive cookies, tokens, browser profile paths, or unrestricted filesystem access.

## Validation Checklist

- Compare raw and processed column names.
- Verify year ranges and row counts.
- Verify there are no unexpected missing values.
- For overlapping raw/final years, join by `year, location, metric, endpoint, agegroup, sex` and confirm numeric values match raw IHME data within tolerance.
- List combinations present in processed output but absent in raw IHME output.
- Confirm no credentials, access tokens, cookies, or personal browser paths were written to reusable files.
