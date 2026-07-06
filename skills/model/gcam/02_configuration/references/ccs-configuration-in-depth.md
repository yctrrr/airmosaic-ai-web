# CCS Configuration In Depth

How CCS (Carbon Capture and Storage) is represented in GCAM-China, the relevant configuration files, and common pitfalls when enabling CCS in scenarios.

## CCS-Related Input Files

| File | Purpose |
|------|---------|
| `CCS_shrwt_CHINA.xml` | Sets technology share-weights for CCS vs non-CCS technologies at province level |
| `Cstorage_CHINA.xml` | Defines carbon storage resource supply curves |
| `no_offshore_ccs.xml` | Sets offshore CCS share weights to zero (effectively disables offshore CCS) |
| `ccs_supply_lowest.xml` | Sets CCS storage supply to lowest cost tier |
| `turn_off_ccs.xml` | Broader CCS disabling file that affects all CCS globally |

## File Relationships

```
Cstorage_CHINA.xml      -> Defines storage resource AVAILABILITY
CCS_shrwt_CHINA.xml     -> Defines CCS technology SHARE WEIGHTS
no_offshore_ccs.xml     -> Zeroes out offshore storage share weights
ccs_supply_lowest.xml   -> Overrides storage supply curve to lowest cost
```

`CCS_shrwt_CHINA.xml` and `Cstorage_CHINA.xml` serve different purposes and can be loaded independently. `CCS_shrwt_CHINA.xml` affects which technologies are chosen; `Cstorage_CHINA.xml` affects the cost of storage once CCS is chosen.

## Common Pitfall: CCS_shrwt_CHINA.xml and N Fertilizer

### The Problem

Loading `CCS_shrwt_CHINA.xml` as-is into a GCAM-China DPEC configuration often fails with:

```
No Discrete Choice function set in AH, N fertilizer
```

### Root Cause

`CCS_shrwt_CHINA.xml` references `N fertilizer` as the sector name for fertilizer CCS weights. But GCAM-China v8 uses `ammonia` as the internal sector name (defined by `gcamchina.FERT_NAME <- "ammonia"` in `constants.R`). The generated `Fert_CHINA.xml` creates provinces with `supplysector name="ammonia"`, not `N fertilizer`.

The path mismatch means BaseX finds no existing node at `AH / N fertilizer`, and the model initialization fails because it cannot add share weights to a nonexistent sector.

### Resolution Options

**Option A: Adapt the CCS XML** — Copy `CCS_shrwt_CHINA.xml` to a new file, replace all `N fertilizer` with `ammonia`, and load that instead.

**Option B: Remove fertilizer blocks** — Remove all `N fertilizer` blocks from the copied file and test with cement/electricity/liquids CCS only.

**Option C: Check GitHub source** — The official `zgcamchina_L2999.ccs_shrwt_CHINA.R` on GitHub may have been updated to use `ammonia`. Regenerate XML from updated R script.

### Loading Order

When adding CCS components, the order in `<ScenarioComponents>` matters:

```xml
<!-- Correct order -->
<ScenarioComponents>
  <Value name="detailed_industry">../input/gcamdata/xml/detailed_industry_CHINA.xml</Value>
  <Value name="cement">../input/gcamdata/xml/cement_CHINA.xml</Value>
  <Value name="fertilizer">../input/gcamdata/xml/Fert_CHINA.xml</Value>
  <!-- CCS can only be added AFTER base sector definitions -->
  <Value name="ccs_shareweights">../input/gcamdata/xml/CCS_shrwt_CHINA_adapted.xml</Value>
  <Value name="no_offshore_ccs">../input/gcamdata/xml/no_offshore_ccs.xml</Value>
</ScenarioComponents>
```

## CCS and Power Sector

In GCAM-China, CCS affects the power sector by splitting coal/gas/liquids/biomass generation into CCS and non-CCS technology variants. This is visible in the output:

- `subsector=coal` with technologies `coal` and `coal CCS`
- `subsector=gas` with technologies `gas` and `gas CCS`

CCS share weights determine what fraction of generation uses each technology.

## CCS in Industrial Sectors

CCS also affects industrial sectors:
- **cement**: `cement` vs `cement CCS`
- **ammonia**: `coal` vs `coal CCS`, `gas` vs `gas CCS`
- **iron and steel**: `BLASTFUR` vs `BLASTFUR CCS`

## Safe CCS Testing Workflow

1. Start with a working configuration without CCS
2. Copy the configuration as a test version
3. Add only `Cstorage_CHINA.xml` first — this only defines storage resources, not technology weights
4. Run a short horizon (e.g., to 2030) and verify no errors
5. Then add adapted CCS share weights one sector at a time
6. Check run log for each addition

## Key Takeaway

`Value name="xxx"` in configuration XML is only a label. The actual file path and internal XML structure determine model behavior. Any new component must reference node paths that already exist in the model.
