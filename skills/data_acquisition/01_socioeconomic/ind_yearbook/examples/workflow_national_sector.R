# =============================================================================
# Example: National Sector-Level Indicators Pipeline
#
# Demonstrates end-to-end processing of national industry category economic 
# indicators from yearbook Excel files.
# =============================================================================

# ---- Setup ----

# Adjust these paths to your environment
yearbook_root <- "path/to/yearbook_root"
sector_code_csv <- "path/to/RESSET_NLC_INDUSTRYCODE_2012__N_1.csv"

setwd(yearbook_root)

suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
  library(stringr)
})

# ---- Configuration ----

output_dir <- file.path(yearbook_root, "economic_indicators")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

yearbook_years <- 2013:2026  # Yearbook edition years

# ---- Helper Functions (from template) ----

source("../../templates/process_regional_sector.R", local = TRUE)

# ---- Step 1: Read Yearly CSVs ----

read_one_national_year <- function(yb_year) {
  sector_dir <- file.path(
    sprintf("中国工业统计年鉴%d（Excel）", yb_year), "2分行业数据"
  )
  csv_path <- file.path(sector_dir, "规模以上工业企业主要经济指标.csv")
  
  if (!file.exists(csv_path)) {
    stop("Missing CSV for yearbook year ", yb_year, ": ", csv_path)
  }
  
  dt <- fread(csv_path)
  dt[, Year := yb_year - 1L]
  dt
}

# ---- Step 2: Build Sector Code Lookup ----

build_sector_lookup <- function(code_csv) {
  sector_table <- fread(code_csv)
  
  # Normalize and extract cat2 and cat4 mappings
  cat2 <- unique(sector_table[!is.na(IndNm2) & IndNm2 != "", .(
    industry_ch = clean_text(IndNm2, remove_space = TRUE),
    sector_code = as.integer(IndCd2),
    sector_level = "cat2"
  )])
  
  cat4 <- unique(sector_table[!is.na(IndNm4) & IndNm4 != "", .(
    industry_ch = clean_text(IndNm4, remove_space = TRUE),
    sector_code = as.integer(IndCd4),
    sector_level = "cat4"
  )])
  
  rbindlist(list(cat2, cat4), fill = TRUE)
}

# ---- Step 3: Merge and Standardize ----

standardize_national <- function(dt, lookup) {
  # Standardize column names
  metric_map <- c(
    "企业单位数个" = "FirmNumberN",
    "工业销售产值当年价格" = "IndustrialSalesValueN",
    "资产总计" = "TotalAssetsN",
    "所有者权益合计" = "TotalNetAssetsN",
    "实收资本" = "PaidInCapitalN",
    "固定资产合计" = "FixedAssetsN",
    "累计折旧" = "FixedAssetDepreciationN",
    "流动资产合计" = "LiquidAssetsN",
    "流动负债合计" = "LiquidLiabilitiesN",
    "从业人员平均人数万人" = "StaffNumberN",
    "营业收入" = "TotalRevenueN",
    "营业成本" = "TotalCostN",
    "营业利润" = "TotalProfitN",
    "利润总额" = "NetProfitN",
    "应交所得税" = "TaxN"
  )
  
  # Match industry codes
  dt[, row_id := .I]
  dt[, industry_ch := clean_text(行业, remove_space = TRUE)]
  dt <- merge(dt, lookup, by = "industry_ch", all.x = TRUE, sort = FALSE)
  setorder(dt, row_id)
  dt[, row_id := NULL]
  
  # Rename metric columns
  for (cn_name in names(metric_map)) {
    if (cn_name %in% names(dt)) {
      setnames(dt, cn_name, metric_map[cn_name])
    }
  }
  
  # Ensure required columns
  for (col in metric_map) {
    if (!col %in% names(dt)) dt[, (col) := NA_real_]
  }
  
  dt
}

# ---- Step 4: Run Pipeline ----

# Read all years
all_years <- rbindlist(lapply(yearbook_years, read_one_national_year), fill = TRUE)
message("Read ", length(unique(all_years)), " data years, ", nrow(all_years), " rows")

# Build lookup and standardize
lookup <- build_sector_lookup(sector_code_csv)
final <- standardize_national(all_years, lookup)

# Write output
output_csv <- file.path(output_dir, "规模以上工业企业主要经济指标2012-2025.csv")
fwrite(final, output_csv, bom = TRUE)
message("Output: ", output_csv, " (", nrow(final), " rows, ", ncol(final), " cols)")
