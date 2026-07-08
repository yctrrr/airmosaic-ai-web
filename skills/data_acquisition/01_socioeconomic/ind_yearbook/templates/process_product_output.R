# =============================================================================
# process_product_output.R
#
# General template: process provincial industrial product output tables
# from industrial statistical yearbook Excel files.
#
# Handles: panel detection, wide-to-long transformation, unit parsing,
# MEIC supplementation (optional), missing data imputation.
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
  library(stringr)
})

# ---- Configuration ----------------------------------------------------------

YEARBOOK_ROOT  <- ""
YEAR_RANGE     <- 2013:2026

# Unicode-safe Chinese string builder (for non-UTF8 locales)
u <- function(codepoints) intToUtf8(codepoints)

# Region whitelist
REGION_NAMES <- c(
  "全国", "北京", "天津", "河北", "山西", "内蒙古", "辽宁", "吉林", "黑龙江",
  "上海", "江苏", "浙江", "安徽", "福建", "江西", "山东", "河南", "湖北",
  "湖南", "广东", "广西", "海南", "重庆", "四川", "贵州", "云南", "西藏",
  "陕西", "甘肃", "青海", "宁夏", "新疆"
)

# ---- Utility Functions ------------------------------------------------------

clean_text <- function(x, remove_space = TRUE) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- str_replace_all(x, "_x000D_", "")
  x <- str_replace_all(x, "[\r\n\t]", "")
  x <- str_replace_all(x, "\u00A0", "")
  x <- str_replace_all(x, "\u3000", "")
  if (remove_space) x <- str_replace_all(x, "\\s+", "") else x <- str_squish(x)
  x
}

clean_col_name <- function(x) {
  x <- clean_text(x, remove_space = TRUE)
  x <- str_replace_all(x, "（", "(")
  x <- str_replace_all(x, "）", ")")
  x <- str_replace_all(x, "：", ":")
  x <- str_replace_all(x, "，", ",")
  x <- str_replace_all(x, "％", "%")
  x <- str_replace_all(x, "地地区|地区地区", "地区")
  x
}

to_numeric <- function(x) {
  raw <- clean_text(x, remove_space = TRUE)
  raw <- str_replace_all(raw, ",|，", "")
  raw <- str_replace_all(raw, "^—(?=[0-9.])", "-")
  raw[raw %in% c("", "-", "—", "…", "...", "－")] <- NA_character_
  suppressWarnings(as.numeric(raw))
}

read_excel_as_text <- function(path, sheet = 1) {
  raw <- suppressMessages(read_excel(path, sheet = sheet,
    col_names = FALSE, col_types = "text", .name_repair = "minimal"))
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  raw[] <- lapply(raw, as.character)
  raw
}

# ---- Panel Detection --------------------------------------------------------

find_header_cells <- function(raw_df) {
  clean_mat <- as.data.frame(lapply(raw_df, clean_text), stringsAsFactors = FALSE)
  header_hits <- which(as.matrix(clean_mat) == "地区", arr.ind = TRUE)
  if (nrow(header_hits) == 0) return(data.table(header_row = integer(), province_col = integer()))
  data.table(
    header_row = as.integer(header_hits[, "row"]),
    province_col = as.integer(header_hits[, "col"])
  )[order(header_row, province_col)]
}

# ---- Product Column Parser --------------------------------------------------

parse_product_col <- function(cols) {
  clean <- clean_col_name(cols)
  has_unit <- str_detect(clean, "\\([^()]+\\)$")
  unit <- ifelse(has_unit, str_match(clean, "\\(([^()]*)\\)$")[, 2], NA_character_)
  product_name <- ifelse(has_unit, str_replace(clean, "\\([^()]*\\)$", ""), clean)
  product_name <- clean_text(product_name, remove_space = TRUE)
  product_name <- str_replace_all(product_name, "^#+", "")  # strip hash prefixes
  
  product_name_unit <- ifelse(is.na(unit) | unit == "", product_name, 
                               paste(product_name, unit, sep = "_"))
  unit_coefficient <- fifelse(
    is.na(unit) | unit == "", NA_real_,
    fifelse(str_detect(unit, "^亿"), 100000000,
            fifelse(str_detect(unit, "^万"), 10000, 1))
  )
  
  data.table(
    original_col = cols,
    product_name = product_name,
    unit = unit,
    product_name_unit = product_name_unit,
    unit_coefficient = unit_coefficient
  )
}

# ---- Wide-to-Long Transformation --------------------------------------------

wide_to_long <- function(dt) {
  base_cols <- c("Year", "yearbook_year", "source_file", "province")
  product_cols <- setdiff(names(dt), base_cols)
  product_cols <- product_cols[vapply(product_cols, function(col) {
    any(!is.na(dt[[col]]))
  }, logical(1))]
  if (length(product_cols) == 0) return(data.table())
  
  for (col in product_cols) dt[[col]] <- to_numeric(dt[[col]])
  
  lookup <- parse_product_col(product_cols)
  long <- melt(dt, id.vars = base_cols, measure.vars = product_cols,
               variable.name = "original_col", value.name = "output",
               variable.factor = FALSE)
  long <- merge(long, lookup, by = "original_col", all.x = TRUE, sort = FALSE)
  long[, original_col := NULL]
  
  setcolorder(long, c(
    "Year", "yearbook_year", "source_file", "province",
    "product_name", "unit", "product_name_unit", "unit_coefficient", "output"
  ))
  long
}

# ---- Missing Data Imputation ------------------------------------------------

fill_yearbook_series <- function(dt, group_cols) {
  years <- 2012:2025  # typical data year range
  keys <- unique(dt[, ..group_cols])
  grid <- CJ(Year = years, keys, unique = TRUE)
  out <- merge(grid, dt, by = c("Year", group_cols), all.x = TRUE)
  
  out[, output := {
    x <- output
    y <- Year
    observed <- which(!is.na(x))
    if (length(observed) == 0L) return(x)
    if (length(observed) == 1L) {
      x[is.na(x)] <- x[observed]
      return(x)
    }
    # Linear interpolation for internal gaps
    approx_vals <- approx(y[observed], x[observed], xout = y, rule = 1)
    fill_idx <- is.na(x) & !is.na(approx_vals)
    x[fill_idx] <- approx_vals[fill_idx]
    # Growth-rate extrapolation for endpoints
    while (any(is.na(x))) {
      miss <- which(is.na(x))[1]
      prev <- which(seq_along(x) < miss & !is.na(x))
      nxt <- which(seq_along(x) > miss & !is.na(x))
      if (length(prev) >= 2L) {
        latest <- tail(prev, 1L); prev2 <- tail(prev, 2L)[1L]
        x[miss] <- if (is.na(x[prev2]) || x[prev2] == 0) x[latest] else x[latest]^2 / x[prev2]
      } else if (length(nxt) >= 2L) {
        first <- nxt[1L]; second <- nxt[2L]
        x[miss] <- if (is.na(x[second]) || x[second] == 0) x[first] else x[first]^2 / x[second]
      } else if (length(prev) == 1L) {
        x[miss] <- x[prev]
      } else if (length(nxt) == 1L) {
        x[miss] <- x[nxt]
      } else break
    }
    x
  }, by = group_cols]
  
  out
}

# ---- Main Entry Point -------------------------------------------------------

process_product_output <- function(
    root = YEARBOOK_ROOT, 
    years = YEAR_RANGE,
    clean_mode = c("wide", "long")
) {
  clean_mode <- match.arg(clean_mode)
  
  year_pattern <- sprintf("中国工业统计年鉴(%s)（Excel）", paste(years, collapse = "|"))
  year_dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  year_dirs <- year_dirs[str_detect(basename(year_dirs), year_pattern)]
  
  all_wide <- list()
  
  for (yd in year_dirs) {
    yb_year <- as.integer(str_extract(basename(yd), "[0-9]{4}"))
    data_year <- yb_year - 1L
    
    # Find product output directory
    product_dir <- file.path(yd, "工业产量")
    if (!dir.exists(product_dir)) {
      product_dir <- file.path(yd, "分地区工业主要产品产量")
      if (!dir.exists(product_dir)) {
        message("Year ", yb_year, ": no product directory, skipping")
        next
      }
    }
    
    files <- list.files(product_dir, full.names = TRUE)
    files <- files[tolower(tools::file_ext(files)) %in% c("xls", "xlsx")]
    files <- files[!str_detect(basename(files), "^~\\$")]
    if (length(files) == 0) next
    
    # Process files (simplified — full version handles sheets, continuations)
    year_data <- list()
    for (f in files) {
      sheets <- tryCatch(excel_sheets(f), error = function(e) character())
      for (sh in sheets) {
        cleaned <- tryCatch({
          raw_df <- read_excel_as_text(f, sheet = sh)
          header_cells <- find_header_cells(raw_df)
          if (nrow(header_cells) == 0) next
          
          # For simplicity, process first panel
          hrow <- header_cells[1]
          pcol <- header_cells[1]
          
          region_rows <- which(
            seq_along(raw_df[[pcol]]) > hrow &
            clean_text(raw_df[[pcol]]) %in% c(REGION_NAMES, "总计", "合计")
          )
          if (length(region_rows) == 0) next
          
          # Build header from rows above data
          header_rows <- max(1L, hrow - 2L):(min(region_rows) - 1L)
          col_names <- vapply(seq_len(ncol(raw_df)), function(j) {
            if (j == pcol) return("province")
            vals <- clean_col_name(unlist(raw_df[header_rows, j], use.names = FALSE))
            vals <- vals[vals != "" & vals != "地区"]
            if (length(vals) == 0) return(paste0("col_", j))
            clean_col_name(paste(unique(vals), collapse = ""))
          }, character(1))
          
          panel_dt <- as.data.table(raw_df[region_rows, , drop = FALSE])
          setnames(panel_dt, col_names)
          panel_dt[, province := clean_text(province)]
          panel_dt[province %in% c("总计", "合计"), province := "全国"]
          panel_dt <- panel_dt[province %in% REGION_NAMES]
          
          # Convert metrics
          metric_cols <- setdiff(names(panel_dt), "province")
          for (mc in metric_cols) panel_dt[[mc]] <- to_numeric(panel_dt[[mc]])
          
          panel_dt[, :=(Year = data_year, yearbook_year = yb_year,
                          source_file = basename(f))]
          setcolorder(panel_dt, c("Year", "yearbook_year", "source_file", "province"))
          panel_dt
        }, error = function(e) NULL)
        
        if (!is.null(cleaned) && nrow(cleaned) > 0) {
          year_data[[length(year_data) + 1]] <- cleaned
        }
      }
    }
    
    if (length(year_data) > 0) {
      combined <- rbindlist(year_data, fill = TRUE)
      combined[, province := clean_text(province)]
      combined[province %in% c("总计", "合计"), province := "全国"]
      
      output_csv <- file.path(yd, "分地区工业主要产品产量.csv")
      fwrite(combined, output_csv, bom = TRUE)
      all_wide[[length(all_wide) + 1]] <- combined
      message("Year ", yb_year, ": ", nrow(combined), " rows -> ", basename(output_csv))
    }
  }
  
  if (length(all_wide) == 0) {
    stop("No product data processed for any year. Check yearbook_root and directory structure.")
  }
  
  # Combine all years
  wide_dt <- rbindlist(all_wide, fill = TRUE)
  setorder(wide_dt, Year, province)
  
  wide_csv <- file.path(root, "分地区工业主要产品产量_raw_wide.csv")
  fwrite(wide_dt, wide_csv, bom = TRUE)
  message("\nRaw wide table: ", wide_csv, " (", nrow(wide_dt), " rows, ", ncol(wide_dt), " cols)")
  
  if (clean_mode == "long") {
    long_dt <- wide_to_long(wide_dt)
    long_csv <- file.path(root, "分地区工业主要产品产量_long.csv")
    fwrite(long_dt, long_csv, bom = TRUE)
    message("Long table: ", long_csv, " (", nrow(long_dt), " rows, ", ncol(long_dt), " cols)")
    return(invisible(list(wide = wide_dt, long = long_dt)))
  }
  
  invisible(wide_dt)
}
