# AirMosaic AI — Agent Integration Guide

AirMosaic AI is a locally deployed atmospheric environment decision intelligence platform. This document tells you (the agent) how to discover capabilities, load skills, access local data, and run analyses safely.

## What You Can Do

- Acquire environmental and socioeconomic data from registered sources
- Run model analyses (GCAM scenario extraction, health impact PAF calculations)
- Generate local template causal-design drafts for policy evaluation
- Query the local data catalog and check availability
- Select modeling strategy by data availability: use transformer-based or other AI models when samples are sufficient; use empirical formulas and expert-reviewed rules when observations are sparse

## Agent Runtime Setup

Install a local coding agent, then open this repository root.

### Codex CLI

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
cd D:\AirMosaicAI\airmosaic-ai-core
codex
```

Codex should read this `AGENTS.md` file from the repository root before operating on the project.

If an agent does not load this file automatically, ask it to read `AGENTS.md` before running commands or editing files.

## Project Setup (One-Time)

```powershell
cd D:\AirMosaicAI\airmosaic-ai-core
pip install -e .[dev]
```

Required environment variable:

```powershell
$env:AIRMOSAIC_LOCAL_WORKSPACE = "D:\AirMosaicAI\local_workspace"
```

This must point to a directory that holds raw data, model releases, API credentials, and runtime outputs. Never write data into the repo directory itself.

## Skill Discovery

All skills live under `skills/`. Each skill is registered via `agents/openai.yaml` with a display name, description, and default prompt:

```
skills/
  data_acquisition/
    01_socioeconomic/
      worldpop/agents/openai.yaml   -> "WorldPop Data Acquisition"
      csmar/agents/openai.yaml       -> "CSMAR Data Downloader"
      ind_yearbook/SKILL.md          -> Industrial yearbook processing
    04_impact/
      ihme-gbd-results/agents/openai.yaml -> "IHME GBD Results"
  model/
    IAM/
      gcam/agents/openai.yaml        -> "GCAM Model Analysis"
    04_impact/
      health_impact_analysis/SKILL.md -> PM2.5 PAF mortality estimation
```

To use a skill, read its `SKILL.md` completely, then follow the instructions in `scripts/`, `templates/`, and `references/` as directed.

## How to Run Analyses

### CLI (for quick checks)

```powershell
airmosaic list-datasets
airmosaic list-datasets --layer 01_socioeconomic
airmosaic list-datasets --skill worldpop
airmosaic list-datasets --domain health
airmosaic check-availability population
airmosaic draft-causal-plan --question "..." --treatment "..." --outcome "..."
```

`list-datasets` reads `skills/data_acquisition/**/datasets.yaml`, not a remote live catalog. It tells agents which datasets can be acquired or processed by the currently installed skills and where to find the responsible skill.

`draft-causal-plan` is a local template generator. It does not call an external LLM or agent. Treat its JSON output as a structured starting point, then extend it with your own reasoning, project skills, and data checks.

### External Agent Workflow

When using Codex or another agent system:

1. Open `D:\AirMosaicAI\airmosaic-ai-core` as the workspace root.
2. Read `AGENTS.md`.
3. Use `airmosaic list-datasets` to inspect datasets declared by data acquisition skills.
4. Use `airmosaic check-availability <dataset_id>` to verify local cache availability.
5. Read the relevant `skills/**/SKILL.md` before running a skill workflow.
6. Use `airmosaic draft-causal-plan ...` only as a local JSON scaffold for causal design.
7. Expand or revise the scaffold through the external agent's own reasoning and, when needed, by reading `workflow/`, `catalog/`, and skill references.

### R Templates (for skill workflows)

Each skill provides template scripts under `templates/` or `scripts/`. Source them in an R session with the required environment variables set:

```r
Sys.setenv(AIRMOSAIC_LOCAL_WORKSPACE = "D:/AirMosaicAI/local_workspace")
source("skills/model/04_impact/health_impact_analysis/templates/calculate_pm25_deaths.R")
```

### Python SDK

```python
from airmosaic_core.services.data_catalog import list_datasets
from airmosaic_core.services.data_access import check_availability
datasets = list_datasets(layer="01_socioeconomic")
available = check_availability("population")
```

## Modeling Strategy

Use data availability to choose the modeling path:

- **Sufficient samples**: prefer transformer-based or other AI models for pattern recognition, high-dimensional interaction discovery, surrogate modeling, and candidate causal-effect screening.
- **Limited samples**: prefer empirical formulas, process-based assumptions, scenario rules, and expert-reviewed correction factors.
- **Borderline cases**: start with empirical formulas as the baseline, then use AI models only for residual pattern detection or sensitivity analysis.

## Data Boundary (Critical)

This repo contains only code, schemas, templates, and documentation. All raw data, model outputs, API keys, and intermediate files go into `$env:AIRMOSAIC_LOCAL_WORKSPACE`.

- Read data from: `$env:AIRMOSAIC_LOCAL_WORKSPACE/data_cache/`
- Write outputs to: `$env:AIRMOSAIC_LOCAL_WORKSPACE/output/`
- Never commit data files to this repo

## Conventions

- **Paths**: Use forward slashes in R (`D:/AirMosaicAI/...`), backslashes in PowerShell
- **Encoding**: All files are UTF-8. R scripts may use Unicode code points (`intToUtf8`) for Chinese strings
- **Skills**: Each skill is self-contained. Read SKILL.md before acting. Templates/ are generic; examples/ show end-to-end usage
- **Agent interface**: Skill-level `agents/openai.yaml` is the canonical registry. If you add a skill, also add its agent yaml
