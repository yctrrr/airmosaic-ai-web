# AirMosaic AI / 清空智枢

**Atmospheric environment decision intelligence platform** — locally deployed, integrating AI agents, multimodal data acquisition, model analysis, and causal inference.

[**中文**](README_ZH.md)

---

## Architecture

```
D:\AirMosaicAI\
  airmosaic-ai-core\     ← This repo (GitHub)
  local_workspace\        ← Raw data, model releases, credentials (local only)
  docs\                   ← Design docs (local only)
```

## Repository Layout

```
catalog/                   Dataset metadata (YAML schemas)
workflow/                  Analysis pipeline templates (4 layers)
AGENTS.md                  Agent-facing setup and operating guide
CLAUDE.md                  Claude Code entrypoint, redirects to AGENTS.md
skills/
  data_acquisition/        Data source connectors — organized by workflow layer
    01_socioeconomic/      WorldPop, CSMAR, industrial yearbook
    02_emission_inventory/ Emission data acquisition
    03_atmospheric_transport/ Air quality & transport data
    04_impact/             GBD Results, health data
  model/                   Model analysis — organized by workflow layer + model type
    01_socioeconomic/      Socioeconomic modeling
    02_emission_inventory/ Emission modeling
    03_atmospheric_transport/ Atmospheric modeling
    04_impact/             Health impact analysis, PM2.5 PAF mortality
    IAM/                   Integrated Assessment Models
      gcam/                GCAM scenario analysis, output structure, config, extraction
src/airmosaic_core/        Python service layer (CLI / SDK backend)
  services/
    data_catalog.py        Dataset registry: query available datasets by layer, domain, format
    data_access.py         Local cache resolution: path lookups, availability checks, checksum validation
    causal_design.py       Causal inference plan generator: treatment/outcome spec -> DAG + estimator
examples/                  Agent call examples (JSON templates)
tests/                     Unit tests
```

## Workflow Pipeline

Four-layer analysis pipeline with AI/empirical method branching:

```
Layer 1: Socioeconomic -> activity levels, energy, end-of-pipe tech
Layer 2: Emission Inventory -> pollutant & carbon emissions
Layer 3: Atmospheric Transport -> concentration field
Layer 4: Impact Assessment -> health burden, economic damage, inequality
```

Method selection follows data availability. For modules with sufficient historical or spatial samples, AirMosaic AI recommends transformer-based or other AI models to accelerate pattern recognition, variable interaction discovery, and causal-effect identification. For modules with limited data, sparse observations, or weak labels, the recommended default is empirical formulas, process-based assumptions, and expert-reviewed correction rules.

## Quick Start

```powershell
# Install
cd D:\AirMosaicAI\airmosaic-ai-core
pip install -e .[dev]

# CLI: list datasets
airmosaic list-datasets

# CLI: check local data availability
airmosaic check-availability population

# CLI: generate a local template causal analysis plan
airmosaic draft-causal-plan --question "Did clean air policy reduce mortality?" --treatment "clean air policy" --outcome "mortality"
```

### External Agent Example

For Codex, Claude Code, or another local agent, start from the repository root and ask the agent to read the project instructions before taking actions:

```text
Open D:\AirMosaicAI\airmosaic-ai-core.
Read AGENTS.md first. If you are Claude Code, also read CLAUDE.md.
List available datasets with `airmosaic list-datasets`.
Check population cache availability with `airmosaic check-availability population`.
Read the relevant `skills/**/SKILL.md` before running any workflow.
Use `airmosaic draft-causal-plan ...` only as a local JSON scaffold, then extend it with your own reasoning.
```

## Skills

Skills are self-contained modules with SKILL.md, scripts/, references/, and examples/. Each skill encapsulates a specific data source, model, or analysis method with its own tooling, documentation, and agent contract.

**data_acquisition/** — connectors for external data sources, organized by the four workflow layers:

- **01 Socioeconomic**: WorldPop population grids, CSMAR financial data, industrial yearbook extraction
- **02 Emission Inventory**: emission factor datasets, sectoral activity data
- **03 Atmospheric Transport**: satellite-derived concentration fields, reanalysis products
- **04 Impact**: IHME GBD mortality/disease burden results

**model/** — analysis and modeling methods, also organized by workflow layer:

- **01-04**: Layer-specific modeling (socioeconomic projection, emission compilation, transport simulation, health impact PAF calculation)
- **IAM/**: Integrated Assessment Models, such as GCAM (scenario config interpretation, BaseX output structure exploration, market price extraction)

## External Agent Interface

*Under development.* The services layer (src/airmosaic_core/services/) exposes a Python SDK and CLI that external agents (Codex, Claude, custom tools) can invoke for data discovery, local cache resolution, and local causal-design templates. MCP tool definitions and REST API are planned.

## Data Boundary

This repo does **NOT** contain: raw environmental data, API keys, or model outputs. Those live in $env:AIRMOSAIC_LOCAL_WORKSPACE.

## Agent Integration

AirMosaic AI is designed to be invoked by AI agents (Codex, Claude Code, custom tools). See [AGENTS.md](AGENTS.md) for setup instructions, skill discovery, and usage conventions.

**Quick start for an agent:**

```powershell
$env:AIRMOSAIC_LOCAL_WORKSPACE = "D:\AirMosaicAI\local_workspace"
pip install -e .[dev]
airmosaic list-datasets
```

Codex should read `AGENTS.md` from the repository root. Claude Code should read `CLAUDE.md`, which points to the same agent guide. Each skill registers its interface in `agents/openai.yaml`; read the relevant `SKILL.md` before running a workflow.

For external agents, the recommended pattern is: open this repository root, read `AGENTS.md`, inspect the relevant `SKILL.md`, call `airmosaic` CLI commands for catalog/cache/template tasks, and then use the agent's own reasoning to extend the returned JSON into a full analysis plan. The CLI does not call an external LLM by itself.

## License

Apache-2.0.
