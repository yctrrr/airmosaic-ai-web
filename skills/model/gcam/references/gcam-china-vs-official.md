# GCAM-China vs Official GCAM-Core

Understanding the differences between GCAM-China (`umd-cgs/gcam-china`) and official GCAM-Core (`JGCRI/gcam-core`) before writing queries or interpreting output.

## Structural Differences

GCAM-China extends official GCAM-Core with:

1. **Province-level disaggregation**: China is modeled as 31 provincial regions plus a national aggregate node, rather than a single "China" region.
2. **Additional sectors**: GCAM-China adds independent sectors that do not exist in official core (e.g., `coke` as a standalone supply sector).
3. **Modified sector configurations**: Some sectors that exist in both versions have different metadata in GCAM-China.

## Sector Differences: Concrete Examples

### Coke

- **GCAM-Core**: Coke does NOT exist as an independent `supplysector=coke`. In `A323.sector.csv`, only `iron and steel` is present.
- **GCAM-China**: Coke is an independent sector. In `A323.sector_China.csv`, `coke` appears with `output-unit=Mt`, `price-unit=1975$/GJ`.

### Iron and Steel

- **GCAM-Core** `A323.sector.csv`: `iron and steel, Mt, EJ, 1975$/kg, -3, industry`
- **GCAM-China** `A323.sector_China.csv`: `iron and steel, Mt, EJ or Mt, 1975$/GJ, 0`

The price unit differs: `1975$/kg` in core vs `1975$/GJ` in China. This means sector cost and physical output cannot be directly multiplied to get a monetary proxy in GCAM-China without unit conversion.

### Cement

- **GCAM-Core**: `cement, Mt, EJ, 1975$/kg`
- **GCAM-China**: Same as core for cement (no override in `sector_China.csv`)

### Ammonia / N fertilizer

- GCAM-China uses `ammonia` as the internal sector name for what is conceptually the fertilizer production sector.
- The R constant `gcamchina.FERT_NAME <- "ammonia"` confirms this mapping.
- Some CCS-related XML files reference `N fertilizer` instead of `ammonia`, which causes initialization failures when loaded directly.

## File Location Differences

| File | GCAM-Core Path | GCAM-China Path |
|------|---------------|-----------------|
| Sector catalog | `energy/A323.sector.csv` | `gcam-china/A323.sector_China.csv` |
| Technology costs | `energy/A323.globaltech_cost.csv` | `gcam-china/A323.globaltech_cost.csv` |
| Detailed industry XML | N/A (no province detail) | `detailed_industry_CHINA.xml` |
| CCS share weights | N/A | `CCS_shrwt_CHINA.xml` |

## When to Check Which Source

- **Writing extraction queries for GCAM-China output**: Always check GCAM-China input files and generated XML, not GCAM-Core defaults.
- **Understanding a sector's conceptual role**: GCAM-Core documentation and source code can be helpful for understanding model logic.
- **Comparing results between versions**: Use official documentation at https://jgcri.github.io/gcam-doc/ for core definitions.

## Key Reference

- GCAM-China GitHub: https://github.com/umd-cgs/gcam-china (branch `gcam-china-v8`)
- GCAM-Core GitHub: https://github.com/JGCRI/gcam-core
- GCAM Documentation: https://jgcri.github.io/gcam-doc/
