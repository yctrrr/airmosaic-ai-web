# =============================================================================
# Example Workflow: PM2.5 Health Impact Assessment
#
# Demonstrates end-to-end PM2.5 premature mortality estimation:
#   1. Set up input data paths
#   2. Run grid-level PAF calculation (GEMM-5COD)
#   3. Generate mortality maps
# =============================================================================

# ---- Step 1: Configure Environment ----

Sys.setenv(
  PM25_HIA_CONC_DIR   = 'path/to/pm25/annual/concentration/data',
  PM25_HIA_POP_DIR     = 'path/to/population/grids',
  PM25_HIA_MORT_FILE   = 'path/to/gbd_mortality_rates.csv',
  PM25_HIA_RR_FILE     = 'path/to/RR_curve_lookup.csv',
  PM25_HIA_OUTPUT_DIR  = 'path/to/output/health_burden',
  PM25_HIA_POP_FILE    = 'path/to/population/Population_g0.1_2023.Rds',
  PM25_HIA_SHP_DIR     = 'path/to/boundary/shapefile',
  PM25_HIA_YEARS       = '2023',
  PM25_HIA_CURVE       = 'GEMM-5COD',
  PM25_HIA_PLOT_YEAR   = '2023'
)

# ---- Step 2: Run Calculation ----

source('../../templates/calculate_pm25_deaths.R')

# Check outputs
output_dir <- Sys.getenv('PM25_HIA_OUTPUT_DIR')
list.files(output_dir, pattern = '*.csv')

# ---- Step 3: Run Visualization ----

source('../../templates/visualize_pm25_deaths.R')

# Check map outputs
list.files(output_dir, pattern = '*.png')

# ---- Step 4: Quick Summary ----

summary_file <- file.path(output_dir, 'pm25_premature_death_summary_GEMM-5COD_2023.csv')
if (file.exists(summary_file)) {
  summ <- data.table::fread(summary_file)
  print(summ)
}

message('PM2.5 HIA workflow complete.')
