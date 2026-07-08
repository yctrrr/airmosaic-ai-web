# Yearbook Pipeline Blueprint

## Data Flow Overview

`
Yearbook Excel Sources (by year)
│
├─[Pipeline 1: National Sector]──────────────────────────────────────┐
│  2分行业数据/*.xlsx                                                │
│  ↓ read_new_cat2_excel()                                           │
│  Yearly CSVs (one per yearbook year)                               │
│  ↓ read_yearly_csvs() + standardize_combined_data()                │
│  economic_indicators/规模以上工业企业主要经济指标{range}.csv          │
│  Columns: Year, sector_ch, sector_code, sector_level,              │
│           sector_cat2_code, sector_cat2_ch, sector_cat4_code,      │
│           sector_cat4_ch, + ~15 economic metrics                   │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
├─[Pipeline 2: Regional Sector]──────────────────────────────────────┤
│  3分地区数据/*.xlsx                                                │
│  ↓ process_year_dir() → clean_region_panel() per file              │
│  Yearly CSVs (per yearbook directory)                              │
│  ↓ read_one_year() + standardize_region_data()                     │
│  economic_indicators/分地区规模以上工业企业主要经济指标{range}.csv    │
│  Columns: Year, province, sector_ch, sector_code, sector_level,    │
│           + ~15 economic metrics (aligned with national schema)    │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
├─[Pipeline 3: Product Output]───────────────────────────────────────┤
│  <year_dir>/工业产量/*.xlsx                                        │
│  ↓ process_year() → clean_product_excel()                          │
│  Yearly CSVs (per yearbook directory)                              │
│  ↓ read_one_year() + merge_product_columns()                       │
│  Raw wide table: 分地区工业主要产品产量{range}_raw.csv              │
│  ↓ year_to_clean_long()                                            │
│  Cleaned long table: 分地区工业主要产品产量{range}.csv              │
│  ↓ + MEIC supplements (heat, coke, cement coal, sinter, etc.)      │
│  physical_output/provincial_industrial_products_{range}_estimated.csv│
│  Columns: Year, province, product_name, unit, output,              │
│           source_level, imputation_status                          │
└────────────────────────────────────────────────────────────────────┘
`

## Pipeline 1: National Sector-Level Indicators

### Steps

1. **Locate source files**: For each yearbook year (2013–2026), find the 2分行业数据/ Excel with pattern 规模以上工业企业主要经济指标*.xlsx
2. **Read Excel as text**: 
`read_excel_as_text()` — no type inference, all columns as character
3. **Locate header**: Find 行业 cell in the text matrix
4. **Identify data rows**: First row with 总计 or 采矿业 in the industry column
5. **Merge headers**: make_new_cat2_header_names() collects cells from header rows above data start, concatenates unique non-empty parts
6. **Clean industry names**: 
`normalize_industry_name()` — standardize separators, fix known typos (e.g., 煤矿采选 → 煤炭开采和洗选业)
7. **Numeric conversion**: 	`to_numeric()` with missing-marker handling
8. **Write yearly CSV**: per yearbook year directory
9. **Combine and code**: Read all yearly CSVs → merge with sector code lookup → output standardized table

### Sector Code Matching

Source: RESSET_NLC_INDUSTRYCODE_2012__N_1.csv (GB/T 4754-2012 categories)

Matching levels:
- **cat2**: 2-digit industry major group (e.g., 06 = 煤炭开采和洗选业)
- **cat4**: 4-digit industry sub-group

Special handling:
- Ambiguous names (one name → multiple codes): flag as `ambiguous` for manual review
- Manual override rules (32+ entries) for names that cannot be matched algorithmically
- Missing major-group rows generated from code × 100 rows

### Output Schema

`
Year, sector_ch, sector_code, sector_level,
sector_cat2_code, sector_cat2_ch, sector_cat4_code, sector_cat4_ch,
metric_index,
FirmNumberN, IndustrialSalesValueN, TotalAssetsN, TotalNetAssetsN,
PaidInCapitalN, FixedAssetsN, FixedAssetDepreciationN,
LiquidAssetsN, LiquidLiabilitiesN, StaffNumberN,
TotalRevenueN, TotalCostN, TotalProfitN, NetProfitN, TaxN
`

## Pipeline 2: Regional Sector-Level Indicators

### Steps

1. **Backup originals**: Create 3分地区数据_copy/ before processing
2. **Filter files**: Exclude non-industry tables, temporary files (~$)
3. **Process each Excel**:
   - Read as character matrix
   - Locate all 地区 header cells → panel definitions
   - For each panel: merge headers, filter region rows, convert to numeric
   - Merge panels horizontally by province
4. **Year 2023 special**: Match main table and continuation table files by table ID, then merge
5. **Write yearly CSV** with cleaning notes
6. **Combine years**: Read all yearly CSVs → match sector codes → standardize → align with national schema

### Panel Detection Detail

Each Excel sheet can contain multiple panels (e.g., left panel for one industry, right panel for another). Detection:
- Find every cell containing 地区
- Each such cell defines a new panel's top-left corner
- Panel right boundary = column before next 地区 in same row (or end of sheet)
- Panel bottom boundary = row before next 地区 in same column (or end of sheet)

### Region Name Cleanup

| Raw | Standardized |
|---|---|
| 总计 | 全国 |
| 合计 | 全国 |
| 地 区 | 地区 (header only) |
| 北  京 | 北京 |

## Pipeline 3: Product Output

### Steps

1. **Locate product files**: In each yearbook directory, find 工业产量/ Excel files
2. **Sort files**: Main tables first, continuation tables last
3. **Process each Excel**:
   - Same panel-based reading as Pipeline 2
   - Extract product names and units from column headers
4. **Write yearly CSV** with cleaning notes
5. **Combine into raw wide table**: 03a — read all years, merge product columns
6. **Convert to clean long table**: 03b — parse product_name(unit) from column headers
7. **Supplement with MEIC data**: 03c — add cement coal use, sinter, heat supply, coke, etc.
8. **Complete missing data**: Interpolation + share-based allocation

### Product Column Merge Rules

Some products appear under slightly different names across years:
`
Target: #啤酒(万千升)                    Source: 啤酒(万千升)       → remove # prefix
Target: 碳酸钠(电石,折100升/千克)(万吨)   Source: 碳酸钠(电石,折100升／千克)(万吨) → unify slash
Target: 磷肥(折含P2O5100%)(万吨)         Source: 磷肥(折合P((2))O5100%)(万吨)  → fix OCR errors
`

### MEIC Supplement Products

| Product | Source | Method |
|---|---|---|
| 石灰, 铸件, 玻璃制品, 砖瓦 | MEIC other industrial products | Direct + fill missing |
| 工业供热, 居民供热 | MEIC heat fuel inputs | Coal → heat energy conversion |
| MEIC火电煤耗 | MEIC electricity-coal fuels | TCE-weighted sum |
| 水泥煤耗量 | MEIC cement workbook | Cement × clinker ratio × technology share × intensity |
| 烧结 | Pig iron × MEIC province ratio | Ratio applied |
| 焦炭 | MEIC coke production fuel | Activity × 100 conversion |
