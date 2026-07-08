# CSMAR API Reference

Key API endpoints observed during CSMAR table download flow.

## Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/csmar-main/single/saveOutline` | POST | Submit query, returns `outlineId` |
| `/api/csmar-main/singleData/pack` | POST | Package download task |
| `/api/csmar-single/single/preview/<condition_id>` | GET | Preview query results |

## Download URL Pattern

```
https://data.csmar.com/sdownload.html
  ?intro=<outlineId>
  &dbName=<encoded_database>
  &tbName=<encoded_table>
  &tbId=<table_id>
  &namePhy=<physical_table_name>
  #/
```

The `outlineId` comes from the `saveOutline` response.

## Field Selection

CSMAR web UI uses a dual-list field selector:
- Left panel: available fields
- Right panel: selected fields
- `全选` button moves all fields from left to right
- Verify `已选：N/N` before submitting

## Data Formats

| Format | Reliability | Notes |
|--------|------------|-------|
| CSV | High | Preferred for large tables |
| TXT | High | Tab-separated, handles encoding well |
| Excel2007 | Medium | May silently drop fields; verify column count |

## Browser Profile

Use a persistent browser profile to maintain login session across downloads:

```
${AIRMOSAIC_LOCAL_WORKSPACE}/.browser_profiles/csmar/
```

The profile stores cookies and login state. Do not commit to version control.
