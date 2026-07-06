# Common Configuration Operations

## Adding a Scenario Component

To add a new component to an existing configuration:

1. Copy the configuration XML as a new file (never modify the original without backup)
2. Add a `<Value>` line inside `<ScenarioComponents>`
3. Place it after the base sector files, before any output settings

```xml
<ScenarioComponents>
  <!-- ... existing components ... -->
  <Value name="new_component_label">../input/gcamdata/xml/new_file.xml</Value>
  <!-- ... remaining components ... -->
</ScenarioComponents>
```

4. Test by running a short horizon first (e.g. 2015-2030 instead of full to 2100)
5. Check run log for parsing errors

## Removing a Component

```xml
<!-- <Value name="component_to_remove">../input/gcamdata/xml/old_file.xml</Value> -->
```

Comment out rather than delete, to preserve a record.

## Common Pitfalls

### Mismatched node paths

The XML file you add must reference nodes that already exist in the model. For example, adding CCS share weights that reference `N fertilizer` when the model uses `ammonia` will cause initialization failure.

**Fix**: check the actual sector names in the existing XML before adding new components. XQuery:

```xquery
distinct-values(collection()/scenario/world/*/*[@type="sector"]/@name)
```

### Missing prerequisite components

Some components depend on others. For example, `CCS_shrwt_CHINA.xml` requires that the basic sector structure (from `detailed_industry_CHINA.xml` or equivalent) is already loaded.

**Fix**: ensure the prerequisite component appears earlier in `<ScenarioComponents>`.

### Order sensitivity

Components are parsed in order. A component that modifies a sector's `StubTechCost` should come after the base sector definition but before any component that depends on that cost value.

## Case Study: Adding CCS Share Weights

### The Problem

Adding `CCS_shrwt_CHINA.xml` directly to a DPEC configuration fails with:

```
No Discrete Choice function set in AH, N fertilizer
```

### Diagnosis Steps

1. Check the run log for the exact error and which file was being parsed
2. Query the existing database for actual sector names:
   ```xquery
   distinct-values(collection()/scenario/world/*[@type="region"]/*[@type="sector"]/@name)
   ```
3. Compare with the sector names in `CCS_shrwt_CHINA.xml`
4. Found: model uses `ammonia`, but CCS file references `N fertilizer`

### Resolution

Option A (recommended): Create an adapted CCS XML with corrected sector names:

```bash
cp CCS_shrwt_CHINA.xml CCS_shrwt_CHINA_adapted.xml
# Replace all `N fertilizer` with `ammonia` in the adapted file
```

Then reference the adapted file in configuration.

Option B: Remove problematic sector blocks and test remaining CCS weights (cement, electricity, liquids) first.

### Prevention

Always verify sector name compatibility before loading new components. The GCAM-China R constant `gcamchina.FERT_NAME` confirms the internal name. See `sector-naming-conventions.md` for the full mapping.

## Log Inspection

After a model run, check:
- `exe/logs/main_log.txt`: overall model status
- `output/<scenario>/run.log`: scenario-specific log
- Search for `ERROR` or `WARNING` in these logs
- Model initialization failures usually appear early in the log
- "Parsing ... scenario component" lines show which XML file was being read when the error occurred

## Safe Configuration Testing

1. Start with a known-working configuration
2. Make one change at a time
3. Run on a subset of periods (e.g. 2015-2025)
4. Compare BaseX output structure (use Layer 01) before and after
5. Check that new nodes appear and old nodes are not corrupted
