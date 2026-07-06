# GCAM Configuration Files Overview

## Structure

A GCAM configuration XML file defines which input files are loaded and in what order. The key section is `<ScenarioComponents>`, which lists XML component files that together build the model.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
  <Files>
    <Value name="xmlInputFileName">...</Value>
    <Value name="xmlInputFileName">...</Value>
    ...
  </Files>
  <ScenarioComponents>
    <Value name="component_name">../input/gcamdata/xml/some_file.xml</Value>
    ...
  </ScenarioComponents>
</Configuration>
```

## Important Rules

1. **`name` is a label, not a model interface.** The `name="component_name"` attribute in `<Value>` is only a descriptive label. The actual file path is what determines model behavior.

2. **Components are parsed in order.** Earlier components set defaults; later components override or extend them. A component that adds CCS share weights must come after the base sector files, or the model may fail to initialize.

3. **Missing nodes cause initialization failures, not silent ignores.** If a component references a sector path that does not exist in the model (e.g. `N fertilizer` vs `ammonia`), the model will fail to initialize with an error like "No Discrete Choice function set."

## Configuration File Locations

In a typical GCAM-China release package:

```text
exe/
  configuration.xml                  (default/reference config)
  configuration_china.xml
  configuration_china_ssp1.xml       (SSP1 baseline)
  configuration_china_ssp2.xml
  ...
  DPEC/
    configuration_dpec_ssp1_19.xml   (DPEC SSP1-1.9)
    configuration_dpec_ssp1_26.xml   (DPEC SSP1-2.6)
    ...
  DPEC_China/
    configuration_dpec_ssp1.xml
    configuration_dpec_ssp1_peak2030_ndc2035.xml
    configuration_dpec_ssp1_peak2030_ndc2035_nz2060.xml
    ...
```

### DPEC Configuration Hierarchy

DPEC configurations follow a layered pattern:

1. **Base GCAM-China config** (`configuration_china.xml`): core solver settings, time periods
2. **SSP config** (`configuration_china_ssp1.xml`): SSP-specific socioeconomic assumptions
3. **DPEC scenario config** (`DPEC/configuration_dpec_ssp*.xml`): emission constraints, policy targets

Each DPEC configuration inherits or overrides components from the base. The output database name is set within the configuration file and becomes the scenario name in BaseX.

## Common Scenario Components in GCAM-China v8

| File | Purpose |
|------|---------|
| `detailed_industry_CHINA.xml` | Detailed industry sector definitions |
| `cement_CHINA.xml` | Cement sector |
| `Fert_CHINA.xml` | Fertilizer / ammonia sector |
| `CCS_shrwt_CHINA.xml` | CCS technology share weights by province |
| `no_offshore_ccs.xml` | Disable offshore CCS |
| `ccs_supply_lowest.xml` | Set CCS supply to lowest cost |
| `Cstorage_CHINA.xml` | Carbon storage resource definitions |
| `turn_off_ccs.xml` | Disable all CCS |
| `renewable_shareweights_ssp1_32.xml` | Renewable share weights for SSP1 |
| `delete_invalid_provinces.xml` | Remove invalid provincial nodes |

## Output Settings

Typical output-related configuration:

```xml
<Value name="xmlDatabaseName">../output/database_basexdb</Value>
<Value name="xmldbLocation">../output</Value>
<Value name="BatchQueryFile">../output/queries/Main_queries.xml</Value>
<Value name="printBatchResult">1</Value>
```

The `xmlDatabaseName` determines the BaseX database path. The scenario name used in XQuery (`@name`) comes from the scenario definition within the configuration, not the database path.

## Safe Modification Workflow

1. Identify the target configuration file
2. Copy it with a descriptive name (e.g., `configuration_test_ccs.xml`)
3. Make one change at a time
4. Run on a subset of periods first
5. Check `exe/logs/main_log.txt` and `output/<scenario>/run.log` for errors
6. Verify output structure with Layer 01 before scaling up

For CCS-specific configuration guidance, see `ccs-configuration-in-depth.md`.
