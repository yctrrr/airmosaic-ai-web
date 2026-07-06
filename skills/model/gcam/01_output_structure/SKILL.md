---
name: gcam-output-structure
description: Explore GCAM BaseX XML output structure. Use when an agent needs to list scenarios, regions, sectors, subsectors, technologies, outputs, inputs, or their tree structure; discover which data nodes exist before writing extraction queries.
---

# GCAM Output Structure Exploration

## Purpose

Before extracting prices, quantities, or technology data from GCAM BaseX output databases, use this layer to understand what is available. This layer provides generic tools to list scenarios, regions, sectors, subsectors, technologies, and their internal node structures without requiring a pre-built sector registry.

## How It Works

GCAM writes model output as XML, stored in a BaseX database. The top-level structure is:

```text
collection()
  -> scenario
    -> world
      -> region
        @type = "region"
        @name = "AH" / "BJ" / ... / "China"
        -> supplysector / pass-through-sector
          -> subsector
            -> technology
              -> output-primary / output / physical-output
              -> input / demand-physical
```

The most common XPath entry point for region-level queries:

```xquery
collection()/scenario/world/*[@type="region"]
```

For China aggregate (not provincial):

```xquery
collection()/scenario/world/*[@type="region" and @name="China"]
```

## Prerequisites

Before running any script in this layer, set these environment variables:

```powershell
$env:GCAM_RELEASE_DIR = "<path to gcam-china-v8-Windows-Release-Package>"
$env:GCAM_BASEX_MAX_MEMORY = "1g"
```

The release package must contain:
- `output/<scenario>/database_basexdb` (BaseX database directories)
- `database_R/Prov_code_china.csv` (province code mapping)

## Quick Tasks

- List all scenarios: use `scripts/inspect_gcam_xml_structure.R` with the `scenarios` query
- List all sectors in a province: read `references/xquery-csv-templates.md`
- Explore subsector/technology tree for a sector: read `references/xpath-structure-guide.md`
- Check price/quantity unit compatibility: read `references/output-price-quantity-units.md`
- Map province codes to names: read `references/province-region-mapping.md`

## Agent Contract

External agents should call a controlled wrapper rather than running BaseX directly. The wrapper accepts:
- `action`: list_scenarios, list_regions, list_sectors, list_subsectors, list_technologies, list_outputs, list_inputs
- `scenario`: scenario name filter
- `region`: region name filter
- `sector`: sector name filter

The agent should never receive direct BaseX Java process execution access.

## References

- `references/xpath-structure-guide.md`: full GCAM XML tree structure with node types and typical paths
- `references/xquery-csv-templates.md`: reusable XQuery templates for CSV output
- `references/output-price-quantity-units.md`: explanation of price-unit vs output-unit and compatibility
- `references/province-region-mapping.md`: province codes, China aggregate node, and mapping conventions
