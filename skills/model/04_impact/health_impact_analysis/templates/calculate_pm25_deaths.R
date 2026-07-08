# =============================================================================
# calculate_pm25_deaths.R
#
# Generalized PM2.5-attributable premature mortality calculation using the
# Population Attributable Fraction (PAF) framework at grid resolution.
#
# Supports GEMM-5COD and IER concentration-response curves.
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
})

# ---- Configuration ----------------------------------------------------------
# Set these before running or pass via environment variables.

# Data paths (user must configure)
pm25_dir        <- Sys.getenv('PM25_HIA_CONC_DIR',    '')
population_dir  <- Sys.getenv('PM25_HIA_POP_DIR',     '')
mortality_file  <- Sys.getenv('PM25_HIA_MORT_FILE',   '')
rr_curve_file   <- Sys.getenv('PM25_HIA_RR_FILE',     '')
output_dir      <- Sys.getenv('PM25_HIA_OUTPUT_DIR',  './output/health_burden')

# Run parameters
years          <- as.integer(strsplit(Sys.getenv('PM25_HIA_YEARS', '2023'), ',')[[1]])
curve_name_sel <- Sys.getenv('PM25_HIA_CURVE', 'GEMM-5COD')

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Utility Functions ------------------------------------------------------

# Round concentration to 0.1 for RR table matching
matchable <- function(x) as.character(round(as.numeric(x), 1))

# Round coordinates to 0.1 degree grid centroid
round_grid_0p1 <- function(x) round(floor(as.numeric(x) * 10) / 10 + 0.05, 2)

# ---- Data Readers (override these for custom data sources) ------------------

read_conc_grid <- function(year, grid_template) {
  # Template: reads gridded PM2.5 concentration data.
  # Override this function for your specific data format.
  #
  # Expected output columns: X_Lon, Y_Lat, concentration
  # Resolution must match population grid template.
  #
  # If your data is in a different format (NetCDF, GeoTIFF, etc.),
  # convert to CSV with lon/lat/value columns first.
  
  conc_file <- file.path(pm25_dir, sprintf('pm25_annual_%s.csv', year))
  if (!file.exists(conc_file)) stop('Missing concentration file: ', conc_file)
  
  conc <- fread(conc_file)
  conc <- merge(grid_template, conc, by = c('X_Lon', 'Y_Lat'), all.x = TRUE)
  conc[, Year := year]
  conc
}

read_pop_grid <- function(year) {
  pop_file <- file.path(population_dir, sprintf('Population_g0.1_%s.Rds', year))
  if (!file.exists(pop_file)) stop('Missing population file: ', pop_file)
  pop <- as.data.table(readRDS(pop_file))
  pop[, Year := as.integer(Year)]
  pop[Year == year & Pop > 0]
}

read_age_structure <- function(year) {
  ag_file <- file.path(population_dir, sprintf('Age_Structure_Fraction_g0.1_%s.Rds', year))
  if (!file.exists(ag_file)) stop('Missing age structure file: ', ag_file)
  ag <- as.data.table(readRDS(ag_file))
  ag[, Year := as.integer(Year)]
  ag[, sex := tolower(sex)]
  ag[, agegroup := as.integer(agegroup)]
  ag[Year == year]
}

read_baseline_mortality <- function(year) {
  mort <- fread(mortality_file)
  mort <- mort[location_name == 'China' & metric == 'Rate']
  mort[, Year := as.integer(year)]
  mort_year <- min(max(mort[['Year']]), year)
  if (mort_year != year) {
    message('Note: using mortality year ', mort_year, ' for target year ', year)
  }
  mort <- mort[Year == mort_year]
  mort[, `:=`(
    endpoint = tolower(endpoint),
    sex = tolower(sex),
    agegroup = as.integer(agegroup)
  )]
  mort
}

read_rr_curve <- function() {
  rr <- fread(rr_curve_file)
  rr <- rr[curve_name == curve_name_sel]
  rr[, `:=`(
    endpoint = tolower(endpoint),
    agegroup = as.integer(agegroup),
    concentration = matchable(concentration)
  )]
  rr <- rr[!is.na(endpoint)]
  if (nrow(rr) == 0) stop('No RR rows found for curve: ', curve_name_sel)
  rr
}

# ---- Core PAF Calculation ---------------------------------------------------

calculate_pm25_death <- function(year) {
  message('====== Year: ', year, ' ======')
  
  # 1. Load inputs
  pop_grid   <- read_pop_grid(year)
  grid_tmpl  <- unique(pop_grid[, .(X_Lon, Y_Lat)])
  conc       <- read_conc_grid(year, grid_tmpl)
  age_struct <- read_age_structure(year)
  baseline   <- read_baseline_mortality(year)
  rr_curve   <- read_rr_curve()
  
  # 2. Match endpoints between RR and baseline mortality
  endpoints <- intersect(unique(rr_curve[['endpoint']]), unique(baseline[['endpoint']]))
  if (length(endpoints) == 0) stop('No shared endpoints between RR and mortality data.')
  message('Matched endpoints: ', paste(endpoints, collapse = ', '))
  baseline <- baseline[endpoint %in% endpoints]
  rr_curve <- rr_curve[endpoint %in% endpoints]
  
  # 3. Cap and match concentration to RR table
  conc[, concentration := fifelse(concentration >= 200, 200, concentration)]
  conc[, concentration := matchable(concentration)]
  
  # 4. Calculate PAF mortality rate per (endpoint, sex, age, concentration)
  mort_ag <- merge(
    baseline[, .(endpoint, sex, agegroup, MortRate)],
    rr_curve[, .(curve_name, endpoint, agegroup, concentration, RR)],
    by = c('endpoint', 'agegroup'),
    allow.cartesian = TRUE
  )
  mort_ag[, paf_mort_rate := MortRate * (RR - 1) / RR / 1e5]
  
  # Collapse 80+ sub-groups
  mort_ag_80plus <- mort_ag[agegroup >= 80,
    .(paf_mort_rate = sum(paf_mort_rate, na.rm = TRUE)),
    by = .(curve_name, endpoint, sex, concentration)]
  mort_ag_under80 <- mort_ag[agegroup < 80]
  mort_ag <- rbindlist(list(
    mort_ag_under80,
    mort_ag_80plus[, .(curve_name, endpoint, sex, agegroup = 80L, concentration, paf_mort_rate)]
  ), use.names = TRUE)
  
  # 5. Grid-level integration
  age_mort <- merge(
    age_struct[, .(X_Lon, Y_Lat, Year, sex, agegroup, AgeStruc)],
    conc[, .(X_Lon, Y_Lat, concentration)],
    by = c('X_Lon', 'Y_Lat')
  )
  age_mort <- merge(age_mort, mort_ag,
    by = c('sex', 'agegroup', 'concentration'), allow.cartesian = TRUE)
  
  if (nrow(age_mort) == 0) stop('No rows after merging age structure, PM2.5, mortality, and RR.')
  
  mort_rate_grid <- age_mort[, .(
    MortRate_PM25 = sum(AgeStruc * paf_mort_rate, na.rm = TRUE)
  ), by = .(X_Lon, Y_Lat, Year, curve_name, concentration)]
  
  # 6. Final attributable deaths
  result <- merge(
    pop_grid[, .(X_Lon, Y_Lat, Year, urarea, Pop)],
    mort_rate_grid,
    by = c('X_Lon', 'Y_Lat', 'Year'),
    all.x = TRUE
  )
  result[is.na(MortRate_PM25), MortRate_PM25 := 0]
  result[is.na(curve_name), curve_name := curve_name_sel]
  result[, Mort := Pop * MortRate_PM25]
  
  # 7. Write outputs
  grid_file <- file.path(output_dir,
    sprintf('pm25_premature_death_grid_%s_%s.csv', curve_name_sel, year))
  fwrite(result, grid_file)
  
  summary_dt <- result[, .(
    Pop = sum(Pop, na.rm = TRUE),
    Mort = sum(Mort, na.rm = TRUE),
    mean_conc = weighted.mean(as.numeric(concentration), Pop, na.rm = TRUE)
  ), by = .(Year, curve_name, urarea)]
  
  summ_file <- file.path(output_dir,
    sprintf('pm25_premature_death_summary_%s_%s.csv', curve_name_sel, year))
  fwrite(summary_dt, summ_file)
  
  message('Wrote: ', grid_file)
  message('Wrote: ', summ_file)
  message('Total deaths: ', round(sum(summary_dt[['Mort']], na.rm = TRUE)))
  
  invisible(result)
}

# ---- Run ----
invisible(lapply(years, calculate_pm25_death))
message('Done.')
