# =============================================================================
# Example: Regional Sector-Level Indicators Pipeline
#
# Demonstrates end-to-end processing of provincial industry economic 
# indicators from yearbook regional Excel files.
# =============================================================================

# ---- Setup ----

yearbook_root <- "path/to/yearbook_root"

setwd(yearbook_root)

# Source the generalized template
source("../../templates/process_regional_sector.R", local = TRUE)

# ---- Step 1: Configure ----

# Override configuration for this run
YEARBOOK_ROOT <- yearbook_root
YEAR_RANGE <- 2013:2026
OUTPUT_DIR <- file.path(yearbook_root, "economic_indicators")

# ---- Step 2: Run ----

# Process all yearbook years
results <- process_all_years(
  root = YEARBOOK_ROOT,
  years = YEAR_RANGE,
  output_dir = OUTPUT_DIR
)

# ---- Step 3: Verify Output ----

message("\n=== Processing Summary ===")
message("Years processed: ", length(unique(results)))
message("Sectors: ", uniqueN(results))
message("Regions: ", uniqueN(results))
message("Total rows: ", nrow(results))
message("Output directory: ", OUTPUT_DIR)

# ---- Step 4: Optional — Run Only Specific Years ----

# process_single_year(
#   year_path = file.path(yearbook_root, "中国工业统计年鉴2025（Excel）"),
#   yearbook_year = 2025
# )
