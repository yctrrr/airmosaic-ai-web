# =============================================================================
# process_regional_sector.R
# 
# General template: process regional industry economic indicators from 
# industrial statistical yearbook Excel files.
#
# Usage: 
#   1. Set year_range and yearbook_root in config or directly below.
#   2. source("process_regional_sector.R")
#   3. Call process_all_years() or process_single_year(year_path)
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
  library(stringr)
})

# ---- Configuration ----------------------------------------------------------
# Override these before running, or source a config file.

YEARBOOK_ROOT  <- ""   # Root directory with yearbook folders
YEAR_RANGE     <- 2013:2026

OUTPUT_DIR      <- file.path(YEARBOOK_ROOT, "economic_indicators")

# Chinese region whitelist (31 provinces + national)
REGION_NAMES <- c(
  "全国", "北京", "天津", "河北", "山西", "内蒙古", "辽宁", "吉林", "黑龙江",
  "上海", "江苏", "浙江", "安徽", "福建", "江西", "山东", "河南", "湖北",
  "湖南", "广东", "广西", "海南", "重庆", "四川", "贵州", "云南", "西藏",
  "陕西", "甘肃", "青海", "宁夏", "新疆"
)

# Exclusion keywords for non-industry classification tables
EXCLUDE_PATTERNS <- c(
  "国有控股", "有限责任公司", "股份有限公司", "私营", "港澳台商",
  "外商投资", "大型", "中型", "小型"
)

# ---- Utility Functions ------------------------------------------------------

clean_text <- function(x, remove_space = TRUE) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- str_replace_all(x, "_x000D_", "")
  x <- str_replace_all(x, "[\r\n\t]", "")
  x <- str_replace_all(x, "\u00A0", "")
  x <- str_replace_all(x, "\u3000", "")
  if (remove_space) {
    x <- str_replace_all(x, "\\s+", "")
  } else {
    x <- str_squish(x)
  }
  x
}

clean_col_name <- function(x) {
  x <- clean_text(x, remove_space = TRUE)
  x <- str_replace_all(x, "[()（）]", "")
  x <- str_replace_all(x, "地地区|地区地区", "地区")
  x <- str_replace_all(x, "[[:punct:]]{2,}", "")
  x
}

convert_numeric_with_issues <- function(x) {
  raw <- as.character(x)
  raw[is.na(raw)] <- ""
  cleaned <- clean_text(raw, remove_space = TRUE)
  cleaned <- str_replace_all(cleaned, ",|，", "")
  cleaned <- str_replace_all(cleaned, "^—(?=[0-9.])", "-")
  cleaned[cleaned %in% c("", "-", "—", "…", "...", "－")] <- NA_character_
  numeric_value <- suppressWarnings(as.numeric(cleaned))
  invalid_n <- sum(!is.na(cleaned) & is.na(numeric_value))
  list(value = numeric_value, invalid_n = invalid_n)
}

read_excel_as_text <- function(path) {
  raw <- suppressMessages(read_excel(path,
    sheet = 1, col_names = FALSE,
    col_types = "text", .name_repair = "minimal"
  ))
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  raw[] <- lapply(raw, as.character)
  raw
}

# ---- Panel Detection --------------------------------------------------------

find_header_cells <- function(raw_df) {
  clean_mat <- as.data.frame(lapply(raw_df, clean_text), stringsAsFactors = FALSE)
  header_hits <- which(as.matrix(clean_mat) == "地区", arr.ind = TRUE)
  if (nrow(header_hits) == 0) {
    return(data.table(header_row = integer(), province_col = integer()))
  }
  data.table(
    header_row = as.integer(header_hits[, "row"]),
    province_col = as.integer(header_hits[, "col"])
  )[order(header_row, province_col)]
}

find_region_rows <- function(raw_df, province_col, header_row, panel_end_row) {
  regions <- clean_text(raw_df[[province_col]], remove_space = TRUE)
  which(seq_along(regions) > header_row & 
        seq_along(regions) <= panel_end_row & 
        regions %in% c(REGION_NAMES, "总计", "合计"))
}

make_header_names <- function(raw_df, header_row, data_start_row, panel_cols, province_col) {
  header_rows <- max(1L, header_row - 2L):(data_start_row - 1L)
  names <- vapply(panel_cols, function(j) {
    if (j == province_col) return("province")
    vals <- unlist(raw_df[header_rows, j], use.names = FALSE)
    vals <- clean_col_name(vals)
    vals <- vals[vals != ""]
    vals <- vals[!vals %in% c("单位亿元", "单位:亿元", "单位：亿元", "地区")]
    vals <- unique(vals)
    clean_col_name(paste(vals, collapse = ""))
  }, character(1))
  empty_cols <- which(names == "")
  names[empty_cols] <- paste0("col_", empty_cols)
  make.unique(names, sep = "_dup")
}

# ---- Core Panel Cleaner -----------------------------------------------------

clean_region_panel <- function(raw_df, header_cells, panel_i) {
  hrow <- header_cells[panel_i]
  pcol <- header_cells[panel_i]
  
  # Determine panel boundaries
  same_row_next <- header_cells[header_row == hrow & province_col > pcol]
  panel_end_col <- if (nrow(same_row_next) > 0) min(same_row_next) - 1L else ncol(raw_df)
  same_col_next <- header_cells[province_col == pcol & header_row > hrow]
  panel_end_row <- if (nrow(same_col_next) > 0) min(same_col_next) - 1L else nrow(raw_df)
  
  region_rows <- find_region_rows(raw_df, pcol, hrow, panel_end_row)
  if (length(region_rows) == 0) stop("No valid region rows in panel")
  
  panel_cols <- pcol:panel_end_col
  header_names <- make_header_names(raw_df, hrow, min(region_rows), panel_cols, pcol)
  
  data_df <- raw_df[region_rows, panel_cols, drop = FALSE]
  names(data_df) <- header_names
  data_dt <- as.data.table(data_df)
  
  # Normalize region names
  data_dt[, province := clean_text(province, remove_space = TRUE)]
  data_dt[province %in% c("总计", "合计"), province := "全国"]
  data_dt <- data_dt[province %in% REGION_NAMES]
  
  # Drop fully empty columns
  metric_cols <- setdiff(names(data_dt), "province")
  keep <- metric_cols[vapply(metric_cols, function(col) {
    any(clean_text(data_dt[[col]]) != "")
  }, logical(1))]
  data_dt <- data_dt[, c("province", keep), with = FALSE]
  
  # Numeric conversion with issue tracking
  issues <- data.table(metric = character(), invalid_n = integer())
  for (col in setdiff(names(data_dt), "province")) {
    conv <- convert_numeric_with_issues(data_dt[[col]])
    data_dt[[col]] <- conv
    if (conv > 0) {
      issues <- rbind(issues, data.table(metric = col, invalid_n = conv))
    }
  }
  
  list(
    data = data_dt,
    header_row = hrow,
    data_rows = nrow(data_dt),
    column_count = ncol(data_dt),
    empty_header_count = sum(str_detect(header_names, "^col_[0-9]+")),
    conversion_issues = issues
  )
}

# ---- File-Level Cleaner -----------------------------------------------------

clean_region_excel <- function(path, yearbook_year, industry_name = NULL) {
  file_name <- basename(path)
  raw_df <- read_excel_as_text(path)
  header_cells <- find_header_cells(raw_df)
  if (nrow(header_cells) == 0) stop("No region header found in: ", file_name)
  
  panel_results <- list()
  for (i in seq_len(nrow(header_cells))) {
    panel <- tryCatch(clean_region_panel(raw_df, header_cells, i), error = function(e) e)
    if (!inherits(panel, "error")) panel_results[[length(panel_results) + 1]] <- panel
  }
  if (length(panel_results) == 0) stop("No valid panels in: ", file_name)
  
  # Merge panels horizontally
  data_dt <- panel_results[[1]]
  if (length(panel_results) > 1) {
    for (i in 2:length(panel_results)) {
      nd <- panel_results[[i]]
      new_cols <- setdiff(names(nd), c("province", names(data_dt)))
      if (length(new_cols) > 0) {
        data_dt <- merge(data_dt, nd[, c("province", new_cols), with = FALSE], 
                         by = "province", all = TRUE)
      }
    }
  }
  
  if (is.null(industry_name)) {
    industry_name <- tools::file_path_sans_ext(file_name)
    industry_name <- str_replace_all(industry_name, "^[0-9]+[-_][A-Za-z0-9]+[-_ ]*", "")
    industry_name <- clean_text(industry_name, remove_space = TRUE)
  }
  
  data_dt <- copy(data_dt)
  data_dt[, :=(
    Year = yearbook_year - 1L,
    yearbook_year = yearbook_year,
    industry_name = industry_name,
    source_file = file_name
  )]
  setcolorder(data_dt, c("Year", "yearbook_year", "industry_name", "source_file", "province"))
  
  # Build log
  issues <- rbindlist(lapply(panel_results, [[, "conversion_issues"), fill = TRUE)
  log <- data.table(
    source_file = file_name,
    industry_name = industry_name,
    header_rows = paste(vapply(panel_results, [[, integer(1), "header_row"), collapse = ";"),
    data_rows = nrow(data_dt),
    column_count = ncol(data_dt),
    issue_count = if (nrow(issues) == 0) 0L else sum(issues)
  )
  
  list(data = data_dt, log = log, conversion_issues = issues)
}

# ---- File Filtering ---------------------------------------------------------

is_excluded_file <- function(file_name) {
  any(str_detect(file_name, fixed(EXCLUDE_PATTERNS)))
}

# ---- Per-Year Processor -----------------------------------------------------

process_single_year <- function(year_path, yearbook_year) {
  region_dir <- file.path(year_path, "3分地区数据")
  if (!dir.exists(region_dir)) {
    message("Year ", yearbook_year, ": no region directory, skipping")
    return(NULL)
  }
  
  files <- list.files(region_dir, pattern = "\\.xlsx$", full.names = TRUE, ignore.case = TRUE)
  files <- files[!str_detect(basename(files), "^~\\$")]
  if (length(files) == 0) {
    message("Year ", yearbook_year, ": no Excel files, skipping")
    return(NULL)
  }
  
  included <- files[!vapply(basename(files), is_excluded_file, logical(1))]
  excluded <- basename(setdiff(files, included))
  
  results <- list()
  logs <- data.table()
  skipped <- character()
  
  for (path in included) {
    cleaned <- tryCatch(
      clean_region_excel(path, yearbook_year),
      error = function(e) e
    )
    if (inherits(cleaned, "error")) {
      skipped <- c(skipped, paste0(basename(path), ": ", cleaned))
      next
    }
    results[[length(results) + 1]] <- cleaned
    logs <- rbind(logs, cleaned, fill = TRUE)
  }
  
  if (length(results) == 0) {
    message("Year ", yearbook_year, ": no processable files")
    return(NULL)
  }
  
  combined <- rbindlist(results, fill = TRUE)
  output_csv <- file.path(year_path, "分地区规模以上工业企业主要经济指标.csv")
  fwrite(combined, output_csv, bom = TRUE)
  
  message("Year ", yearbook_year, ": ", nrow(combined), " rows, ", ncol(combined), " cols -> ", basename(output_csv))
  message("  Included: ", length(included), ", excluded: ", length(excluded), ", skipped: ", length(skipped))
  
  invisible(list(data = combined, csv = output_csv, log = logs, excluded = excluded, skipped = skipped))
}

# ---- Main Entry Point -------------------------------------------------------

process_all_years <- function(root = YEARBOOK_ROOT, years = YEAR_RANGE, output_dir = OUTPUT_DIR) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  year_pattern <- sprintf("中国工业统计年鉴(%s)（Excel）", paste(years, collapse = "|"))
  year_dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  year_dirs <- year_dirs[str_detect(basename(year_dirs), year_pattern)]
  
  all_data <- list()
  for (yd in year_dirs) {
    yb_year <- as.integer(str_extract(basename(yd), "[0-9]{4}"))
    result <- process_single_year(yd, yb_year)
    if (!is.null(result)) all_data[[length(all_data) + 1]] <- result
  }
  
  # Combine all years
  combined <- rbindlist(lapply(all_data, [[, "data"), fill = TRUE)
  final_csv <- file.path(output_dir, "分地区规模以上工业企业主要经济指标_all.csv")
  fwrite(combined, final_csv, bom = TRUE)
  
  message("\nDone. Combined output: ", final_csv, " (", nrow(combined), " rows)")
  invisible(combined)
}
