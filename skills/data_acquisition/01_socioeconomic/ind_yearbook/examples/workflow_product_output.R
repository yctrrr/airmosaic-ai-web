# =============================================================================
# Example: Product Output Pipeline
#
# Demonstrates end-to-end processing of provincial industrial product output
# from yearbook Excel files, with wide-to-long transformation.
# =============================================================================

# ---- Setup ----

yearbook_root <- "path/to/yearbook_root"

setwd(yearbook_root)

# Source the generalized template
source("../../templates/process_product_output.R", local = TRUE)

# ---- Step 1: Configure ----

YEARBOOK_ROOT <- yearbook_root
YEAR_RANGE <- 2013:2026

# ---- Step 2: Run ----

# Process all years → output both wide and long tables
result <- process_product_output(
  root = YEARBOOK_ROOT,
  years = YEAR_RANGE,
  clean_mode = "long"
)

# ---- Step 3: Inspect Results ----

message("\n=== Product Output Summary ===")

# Wide table quick stats
if (!is.null(result)) {
  wide <- result
  product_cols <- setdiff(names(wide), c("Year", "yearbook_year", "source_file", "province"))
  message("Wide table: ", nrow(wide), " rows × ", ncol(wide), " cols (", 
          length(product_cols), " products)")
}

# Long table quick stats
if (!is.null(result)) {
  long <- result
  message("Long table: ", nrow(long), " rows × ", ncol(long), " cols")
  message("Unique products: ", uniqueN(long))
  message("Year coverage: ", paste(range(long, na.rm = TRUE), collapse = "-"))
}

# ---- Step 4: Product Coverage Quick Check ----

if (!is.null(result)) {
  coverage <- result[, .(
    nonmissing_years = sum(!is.na(output)),
    total_years = .N
  ), by = .(product_name, unit)]
  
  # Show products with partial coverage (may need imputation)
  partial <- coverage[nonmissing_years < total_years & nonmissing_years > 0]
  if (nrow(partial) > 0) {
    message("\nProducts with partial year coverage:")
    print(partial[order(nonmissing_years)])
  }
}
