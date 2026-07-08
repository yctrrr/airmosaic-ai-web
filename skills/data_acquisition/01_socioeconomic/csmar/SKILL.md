---
name: csmar-downloader
description: Download CSMAR financial and enterprise data after browser login. Extracts listed-company basic information and filters target-industry candidates for socioeconomic analysis.
---

# CSMAR Data Downloader

Download CSMAR (China Stock Market & Accounting Research) data tables from `https://data.csmar.com/` for socioeconomic driver analysis (workflow Layer 1).

## Workflow Layer

01_socioeconomic — provides listed-company activity data for industrial output, energy consumption, and end-of-pipe technology analysis.

## Prerequisites

- Playwright installed: `pip install playwright && playwright install chromium`
- CSMAR account with institutional access
- Python 3.10+ with pandas, openpyxl

## Download Workflow

CSMAR downloads require two steps:
1. Submit a query in the CSMAR web UI to create a download record.
2. Open the generated `sdownload.html?...` page and click the final local-save button.

### Browser Automation

```js
const { chromium } = await import("playwright");
const context = await chromium.launchPersistentContext(
  "${AIRMOSAIC_LOCAL_WORKSPACE}/.browser_profiles/csmar",
  {
    headless: false,
    viewport: null,
    acceptDownloads: true,
    args: ["--start-maximized"]
  }
);
```

### Step-by-Step

1. Open `https://data.csmar.com/` in the browser.
2. Check login state. If not authenticated or logged into a wrong account, stop and ask user to log in manually. Continue only after user confirms login.
3. Navigate to the target table (e.g., listed-company basic information: `https://data.csmar.com/csmar.html#/datacenter/singletable/search?databaseId=176`).
4. Click **全选** (Select All) in the field selection panel. Verify the selection changes to `已选：N/N`.
5. Preview data to validate field selection and query size.
6. Submit the download task.
7. Open the download records page or directly open: `https://data.csmar.com/sdownload.html?intro=<outlineId>&dbName=<encoded_db>&tbName=<encoded_table>&tbId=<table_id>&namePhy=<physical_table>#/`
8. Click the local-save data button. Save the zip to `${AIRMOSAIC_LOCAL_WORKSPACE}/data_cache/csmar/`.

### Field Selection Rules

- Always click **全选** for each table. Do not rely on default fields.
- Verify the final `sdownload.html` page lists all expected fields.
- If Excel export contains fewer columns than selected, retry with CSV or TXT format.
- Validate: exported column count >= field description file column count.

### Manual Login Policy

Do not automate CSMAR login. When login is needed:
1. Open visible browser.
2. Ask user to complete login manually.
3. Continue only after user confirms.

## Core Table: Listed Company Basic Information

Entry point:
```
https://data.csmar.com/csmar.html#/datacenter/singletable/search?databaseId=176
```

Key fields to include:
- Stock code, stock short name
- Statistical cutoff date
- Industry name and code (CSRC classification)
- Unified social credit code
- Chinese full name
- Province, city
- Main business
- Listing status

## Postprocessing

Use the bundled script to extract target-industry company candidates from the CSMAR company info zip:

```powershell
python scripts/process_listed_company_basic_info.py \
  --zip "${AIRMOSAIC_LOCAL_WORKSPACE}/data_cache/csmar/<downloaded>.zip" \
  --out-dir "${AIRMOSAIC_LOCAL_WORKSPACE}/outputs/csmar"
```

Outputs:
- `csmar_target_industry_company_candidates.csv` — all sector-matched rows
- `csmar_target_industry_company_list_latest.csv` — deduplicated latest company records
- `csmar_target_industry_company_list_latest.xlsx` — Excel with both sheets

Target sectors screened: thermal power, district heating, iron/steel, non-ferrous metals, cement, lime, brick/tile, glass, chemical industry.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Excel export missing fields | Retry with CSV or TXT format |
| Download canceled by browser | Check `chrome://downloads/`; retry the final page click |
| Wrong account logged in | Use user menu logout, ask user to re-login |
| Field count mismatch | Re-select all fields, re-submit query |

## References

- `references/csmar-api.md`: API endpoints and network flow
- `examples/csmar_company_query.json`: Example query parameters
