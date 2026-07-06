---
name: gcam-configuration
description: Understand GCAM configuration files, scenario components, SSP-RCP setup, input data processing chains, CCS configuration, and sector naming conventions. Use when an agent needs to inspect, explain, or modify GCAM configuration XML files; understand how scenarios are defined; trace an input parameter from CSV through R processing to XML and BaseX output; or diagnose CCS-related configuration issues.
---

# GCAM Configuration Reference

## Purpose

This layer provides reference documentation for GCAM configuration. It is not designed for automated model execution, but for helping agents understand:

- How configuration XML files define scenario components
- How SSP-RCP scenario combinations are set up
- How input CSV data flows through R processing scripts into model XML
- Common configuration manipulation operations and their risks
- CCS configuration specifics and common pitfalls
- Sector naming conventions and internal name mappings

## Prerequisites

Access to a GCAM release package directory, set via:

```powershell
$env:GCAM_RELEASE_DIR = "<path to gcam-china-v8-Windows-Release-Package>"
```

## Quick Tasks

- Understand configuration structure: read `references/configuration-files-overview.md`
- Understand SSP-RCP scenario setup: read `references/ssp-rcp-scenario-setup.md`
- Trace input data to output: read `references/input-data-chain-tracing.md`
- Modify a configuration safely: read `references/common-config-manipulation.md`
- Diagnose CCS configuration issues: read `references/ccs-configuration-in-depth.md`
- Look up sector names and mappings: read `references/sector-naming-conventions.md`

## Agent Contract

External agents should call controlled wrappers such as:
- `inspect_gcam_config`: list scenario components, their order, and file paths
- `explain_scenario_setup`: describe what a scenario configuration does
- `trace_input_to_output`: trace a parameter from input CSV to BaseX output
- `diagnose_ccs_config`: check CCS file compatibility with current model

The agent must not receive direct filesystem write access outside the configured local workspace.
