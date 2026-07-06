# AirMosaic AI Core

AirMosaic AI Core is the service and skill layer for **AirMosaic AI / 清空智枢**，an atmospheric-environment decision intelligence platform.

This repository is designed to be uploaded to GitHub. It contains metadata, data acquisition skills, service interfaces, and lightweight examples. It does **not** contain large raw datasets, private download links, API keys, local cache files, or model outputs.

## Scope

- Data catalog metadata and schemas.
- Data acquisition skills, starting with TAP PM2.5.
- Model analysis skills, starting with GCAM scenario and unit-price analysis.
- Data catalog and data access services for external agents.
- Model-design and causal-design service boundaries.
- MCP, REST/OpenAPI, CLI, and Python SDK interface scaffolding.

## First-Stage Services

- `DataCatalogService`: list, search, and describe registered datasets.
- `DataAccessService`: inspect local cache availability without guessing paths.
- `CausalDesignService`: draft causal-analysis plans for policy and exposure questions.

## Repository Layout

```text
catalog/                  Dataset metadata and schemas
skills/data_acquisition/  Reusable data acquisition skills
skills/model/             Reusable model analysis skills
src/airmosaic_core/       Python service package
interfaces/               MCP, REST, CLI, Python SDK boundaries
examples/                 Lightweight examples
tests/                    Unit tests
```

## Local Workspace

Large data and secrets should live in:

```text
D:\AirMosaicAI\local_workspace
```

Do not commit local data or private credentials.
