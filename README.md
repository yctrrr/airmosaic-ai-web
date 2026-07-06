# AirMosaic AI / 清空智枢

Atmospheric-environment decision intelligence platform. This monorepo contains both the AI agent-facing service/skill core and the web frontend.

## Repository Layout

```text
# Core — skills, services, catalog (agent-facing)
skills/                   Reusable skills for data acquisition and model analysis
skills/data_acquisition/  WorldPop, GBD, and other data acquisition skills
skills/model/             GCAM scenario analysis and configuration skills
catalog/                  Dataset metadata and schemas
src/airmosaic_core/       Python service package (DataCatalog, DataAccess, CausalDesign)
examples/                 Agent call examples
tests/                    Unit tests

# Web — frontend (user-facing)
index.html                Static site entry point
app.js                    Application logic
styles.css                Stylesheet
public/                   Static assets
docs/                     Design specs and screenshots
```

## Scope

- Data catalog metadata and schemas
- Data acquisition and model analysis skills for external AI agents
- GCAM output structure exploration, configuration, and data extraction
- MCP, REST/OpenAPI, CLI, and Python SDK service interfaces
- Atmospheric-environment decision intelligence web frontend

## Quick Start

### Core services

```powershell
cd src/airmosaic_core
pip install -e ".[dev]"
python -m airmosaic_core.cli
```

### Web frontend

```powershell
python -m http.server 5176 --bind 127.0.0.1
```

Then open http://127.0.0.1:5176/.

## GitHub Pages

This static site can be published from the repository root on the `main` branch:

1. Repository `Settings > Pages`
2. Source: `Deploy from a branch`
3. Branch: `main`, folder: `/ (root)`
4. Save

## Data Boundary

This repository does NOT contain: raw environmental datasets, GCAM model releases, BaseX databases, private credentials, API keys, or model outputs. Large data belongs in `${AIRMOSAIC_LOCAL_WORKSPACE}`.

## License

Apache-2.0. See `LICENSE`.
