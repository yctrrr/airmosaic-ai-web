# GCAM Skill Data Boundary

## Belongs In This Skill

- XQuery/XPath templates and patterns
- Python/R scripts that query BaseX via parameterized calls
- Reference documentation about GCAM output structure, configuration, and input chain
- Example JSON request payloads for agent wrappers
- Unit and scenario naming conventions

## Does NOT Belong In This Skill

- GCAM model releases, executables, or Java binaries
- BaseX database directories or their contents
- Scenario output files (CSV, XML, PNG) ? keep in `${AIRMOSAIC_LOCAL_WORKSPACE}`
- Raw input CSV data used to build model scenarios
- Generated intermediate files (sector registries, method registries)
- Project-specific analysis outputs
- Large data archives (zip, tar, parquet)
- Personal browser profiles, cookies, or session tokens
- Private download URLs, API keys, or credentials
- Absolute local paths containing user home or workspace names

## Where Outputs Go

All extracted data, plots, and generated files go to:

```text
${AIRMOSAIC_LOCAL_WORKSPACE}/outputs/gcam/
```

or a directory configured by:

```text
${UNIT_PRICE_OUT_DIR}
```

This directory is local-only and is not committed to GitHub.

## Where GCAM Release Package Lives

The GCAM release package (containing `exe/`, `input/`, `output/`, `libs/`) must be installed separately by the user. Use:

```powershell
$env:GCAM_RELEASE_DIR = "<path to release package>"
```

This path is not stored in skill files.
