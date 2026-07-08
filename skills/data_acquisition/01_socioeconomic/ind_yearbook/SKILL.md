---
name: ind-yearbook
description: Process industrial statistical yearbook data (Excel) into standardized CSV tables. Handles national/regional sector-level economic indicators and product output across multiple yearbook editions. Use when an agent or analyst needs to extract, clean, combine, and code industrial yearbook panels into analysis-ready structured tables.
---

# Industrial Yearbook Data Processing

## Purpose

Extract, clean, standardize, and combine multi-year industrial statistical yearbook Excel data into structured CSV tables. Supports three standard pipelines:

- **Sector-level economic indicators** (national by industry category)
- **Regional sector-level indicators** (province × sector panels)
- **Product output** (province × product panels, with optional external supplementation)

## Input Data Structure

Yearbook Excel files are organized as:

`	ext
<yearbook_root>/
  中国工业统计年鉴2013（Excel）/
    2分行业数据/                     # Cat2 sector tables
      规模以上工业企业主要经济指标*.xlsx
    3分地区数据/                     # Regional tables
      按地区分组的<industry_name>主要经济指标.xlsx
  中国工业统计年鉴2014（Excel）/
    ...
`

Each regional Excel contains one or more **panels** identified by a 地区 (region) header cell. Panels share the same structure: region/province names in one column, metric headers spanning one or more merged rows above the data.

## Pipelines At a Glance

| Pipeline | Entry Script | Input | Output |
|---|---|---|---|
| National sector | 	emplates/process_national_sector.R | 2分行业数据/ Excel files | economic_indicators/规模以上工业企业主要经济指标{year_range}.csv |
| Regional sector | 	emplates/process_regional_sector.R | 3分地区数据/ Excel files | economic_indicators/分地区规模以上工业企业主要经济指标{year_range}.csv |
| Product output | 	emplates/process_product_output.R | Product Excel files + optional MEIC | physical_output/provincial_industrial_products_{year_range}_estimated.csv |

## Generalized Processing Techniques

### 1. Panel-Based Excel Reading

Yearbook Excel files use a "地区" cell as the panel anchor. Core algorithm:

`
1. Read entire Excel sheet as character matrix (no type inference)
2. Locate all "地区" cells → each defines a panel's position
3. For each panel:
   a. Determine column span (next "地区" col → right boundary)
   b. Determine row span (next "地区" row → bottom boundary)
   c. Merge multi-row headers above data start
   d. Filter rows against region whitelist
   e. Convert metric columns to numeric with issue logging
`

### 2. Industry Name Standardization + Code Matching

- Normalize: remove spaces, invisible chars, trailing dots; unify parentheses; apply regex rewrite rules for known variants
- Match against a sector code lookup table (GB/T 4754 categories)
- Fall back to **manual override rules** for ambiguous names (e.g., 其他采矿业 → code 1200)
- Handle GB18030 bytes misread as other encodings: iconv(x, from="GB18030", to="UTF-8") with heuristic detection

### 3. Region Whitelist

Keep only recognized 31 mainland China provinces + 全国:

`
region_names <- c(
  "全国", "北京", "天津", "河北", "山西", "内蒙古", "辽宁", "吉林", "黑龙江",
  "上海", "江苏", "浙江", "安徽", "福建", "江西", "山东", "河南", "湖北",
  "湖南", "广东", "广西", "海南", "重庆", "四川", "贵州", "云南", "西藏",
  "陕西", "甘肃", "青海", "宁夏", "新疆"
)
`

Normalize: 合计 and 总计 → 全国; remove all spaces and invisible characters.

### 4. Encoding Repair

Chinese text misread as GB18030 bytes is common in yearbook files. Detection: convert all column names via iconv(x, from="GB18030", to="UTF-8"); if the output contains more valid Chinese characters than the original, apply the conversion globally.

### 5. Multi-row Header Merging

Headers may span 2-3 rows. Merge logic:
- Collect all non-empty cells from header rows above the first data row
- Filter out unit annotations (e.g., 单位亿元)
- Concatenate unique parts, remove spaces
- Fill empty columns with col_<index>

### 6. Main/Continuation Table Pairing (2023 special case)

The 2023 yearbook splits each industry into a main table and continuation tables. Pair them by matching numeric table IDs extracted from file names, then merge horizontally by province.

### 7. Non-Industry Table Exclusion

Exclude files whose names match organization-type keywords that are not industry classifications:

`
国有控股 | 有限责任公司 | 股份有限公司 | 私营 | 港澳台商 | 外商投资 | 大型 | 中型 | 小型
`

### 8. Numeric Conversion with Issue Tracking

Convert cell text to numeric:
- Remove commas, full-width commas, spaces
- Handle negative indicators: — prefix, parenthesized values
- Recognize common missing markers: -, —, …, ...
- Track cells that fail conversion for downstream quality review

### 9. Wide-to-Long Transformation (Product Output)

Product output data starts as wide tables (products as columns). Transform:
`
Year, province, 水泥(万吨), 粗钢(万吨), ...
→
Year, province, product_name, unit, output
`
Parse product name and unit from column headers via product_name(unit) pattern, compute unit coefficients (万 → 10000, 亿 → 100000000).

### 10. Missing Data Imputation

- **Partial province missing**: fill with 0 if other provinces have data
- **Full year-product missing**: interpolate national series, then allocate to provinces by latest available share
- **Series endpoints**: extrapolate using two-year growth rates

### 11. Cleaning Report Generation

Each processing run generates a markdown report with:
- Input/output file paths
- Processing scope and rules
- Per-file processing logs (header rows, data rows, column counts, issues)
- Conversion problem records
- Skipped/excluded file lists
- Quality check results (region coverage, key metrics)

## Non-Industry Table Exclusion

Exclude tables organized by enterprise registration type rather than industry classification:

| Keyword | Meaning |
|---|---|
| 国有控股 | State-controlled |
| 有限责任公司 | Limited liability |
| 股份有限公司 | Joint-stock |
| 私营 | Private |
| 港澳台商 | HK/Macau/Taiwan |
| 外商投资 | Foreign-invested |
| 大型/中型/小型 | Large/medium/small scale |

## Agent Contract

External agents should interact through a wrapper that validates:

- Yearbook root directory path
- Which pipeline to run (sector/region/product)
- Year range
- Output directory (must stay within configured workspace)
- Whether to generate cleaning reports

Agents should not receive unrestricted filesystem access or paths outside the workspace root.

## Configuration

See 	emplates/config.yaml for adjustable parameters:
- Year range
- Region whitelist
- Sector code lookup path
- Exclude patterns
- Output directories

## References

- eferences/pipeline_blueprint.md: Full technical description of each pipeline and data flow
- eferences/industry_code_matching.md: Sector code matching rules and manual override cases
- eferences/encoding_repair.md: GB18030 detection and repair methods

## Examples

- examples/workflow_national_sector.R: End-to-end national sector pipeline
- examples/workflow_regional_sector.R: End-to-end regional sector pipeline
- examples/workflow_product_output.R: End-to-end product output pipeline
