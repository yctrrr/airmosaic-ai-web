# AirMosaic AI / 清空智枢

**Atmospheric environment decision intelligence platform** — locally deployed, integrating AI agents, multimodal data acquisition, model analysis, and causal inference.

[**中文**](README_ZH.md)

---

## Architecture

```
D:\AirMosaicAI\
  airmosaic-ai-core\     ← This repo (GitHub)
  web\                    ← Web frontend (local only)
  local_workspace\        ← Raw data, model releases, credentials (local only)
  docs\                   ← Design docs (local only)
```

## Repository Layout

```
catalog/                   Dataset metadata (YAML schemas)
skills/
  data_acquisition/       WorldPop, GBD data acquisition
  model/                  GCAM scenario analysis, config, extraction
src/airmosaic_core/       Python service package
  services/
    data_catalog.py        Dataset registry queries
    data_access.py         Local cache checks, path resolution
    causal_design.py       Causal analysis plan generation
examples/                 Agent call examples (JSON templates)
tests/                    Unit tests
```

## Quick Start

```powershell
# Install
cd D:\AirMosaicAI\airmosaic-ai-core
pip install -e ".[dev]"

# CLI: list datasets
airmosaic list-datasets

# CLI: check local data availability
airmosaic check-availability population

# CLI: generate causal analysis plan
airmosaic draft-causal-plan --question "Did clean air policy reduce mortality?" --treatment "clean air policy" --outcome "mortality"
```

## Skills

Each skill is a self-contained module with `SKILL.md`, `scripts/`, `references/`, and `examples/`.

| Skill | Purpose |
|-------|---------|
| WorldPop | Download population grids by country/year, with clipping and validation |
| GBD Results | Fetch mortality rates and disease burden from IHME GBD |
| GCAM | Explore BaseX output, interpret config, extract prices/quantities via XQuery |

GCAM skill has three layers:
- **01_output_structure**: XPath/XQuery exploration of scenarios, regions, sectors, technologies
- **02_configuration**: SSP-RCP setup, CCS config, input data chain tracing
- **03_data_extraction**: Market/sector price extraction, technology component decomposition, province aggregation

## External Agent Interface

Platform capabilities are exposed via three interfaces:

- **MCP Tools**: Structured JSON function calls for Codex, Claude, etc.
- **REST / OpenAPI**: Standard HTTP API for web frontends and services
- **Python SDK / CLI**: Local scripts, Jupyter notebooks, batch processing

Agents never access the filesystem directly. All data I/O goes through service interfaces.

## Data Boundary

This repo does **NOT** contain: raw environmental data, GCAM model releases, BaseX databases, API keys, or model outputs. Those live in `$env:AIRMOSAIC_LOCAL_WORKSPACE`.

## License

Apache-2.0.
