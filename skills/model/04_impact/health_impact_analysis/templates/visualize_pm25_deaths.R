# =============================================================================
# visualize_pm25_deaths.R
#
# Generate PM2.5-attributable premature mortality maps from grid-level
# calculation output. Binned choropleth with Spectral palette.
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(sf)
  library(RColorBrewer)
})

# ---- Configuration ----------------------------------------------------------

output_dir       <- Sys.getenv('PM25_HIA_OUTPUT_DIR', './output/health_burden')
year_sel         <- as.integer(Sys.getenv('PM25_HIA_PLOT_YEAR', '2023'))
curve_name_sel   <- Sys.getenv('PM25_HIA_CURVE', 'GEMM-5COD')
population_file  <- Sys.getenv('PM25_HIA_POP_FILE', '')
shp_dir          <- Sys.getenv('PM25_HIA_SHP_DIR', '')

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Plot parameters
urarea_levels <- c('overall', 'urban', 'other')
grid_cell_size <- 0.1  # degrees

# ---- Bin Configuration ------------------------------------------------------

death_breaks  <- c(-Inf, 1, 5, 10, 25, 50, 75, 100, 150, Inf)
death_colors  <- setNames(
  rev(brewer.pal(length(death_breaks) - 1, 'Spectral')),
  sapply(seq_len(length(death_breaks) - 1), function(i) {
    lo <- death_breaks[i]; hi <- death_breaks[i + 1]
    if (is.infinite(lo) && lo < 0) return(paste0('< ', hi))
    if (is.infinite(hi) && hi > 0) return(paste0('> ', lo))
    paste0(lo, '-', hi)
  })
)

# ---- Data Preparation -------------------------------------------------------

read_population <- function() {
  if (!file.exists(population_file)) stop('Population file not found: ', population_file)
  pop <- as.data.table(readRDS(population_file))
  pop[, Year := as.integer(Year)]
  pop[Year == year_sel & urarea %in% urarea_levels & is.finite(X_Lon) & is.finite(Y_Lat)]
}

prepare_plot_data <- function(dt, target_crs, cell_size = grid_cell_size) {
  half <- cell_size / 2
  grid_geom <- st_sfc(
    lapply(seq_len(nrow(dt)), function(i) {
      x0 <- dt[['X_Lon']][i] - half; x1 <- dt[['X_Lon']][i] + half
      y0 <- dt[['Y_Lat']][i] - half;  y1 <- dt[['Y_Lat']][i] + half
      st_polygon(list(matrix(c(x0, y0, x1, y0, x1, y1, x0, y1, x0, y0), ncol = 2, byrow = TRUE)))
    }), crs = 4326)
  st_transform(st_sf(as.data.frame(dt), geometry = grid_geom), target_crs)
}

# ---- Map Generation ---------------------------------------------------------

plot_mortality_map <- function(plot_data, boundary, title_expr) {
  ggplot(plot_data) +
    geom_sf(aes(fill = Mort_bin), color = NA) +
    geom_sf(data = boundary, fill = NA, color = 'grey45', linewidth = 0.25) +
    scale_fill_manual(
      name = title_expr,
      values = death_colors,
      na.value = 'white',
      drop = FALSE,
      guide = guide_legend(
        ncol = 1, byrow = TRUE, title.position = 'right',
        title.hjust = 0.5, title.vjust = 0.5,
        title.theme = element_text(size = 22, angle = 270),
        label.theme = element_text(size = 18),
        override.aes = list(alpha = 1)
      )
    ) +
    theme_bw(base_size = 18) +
    theme(
      axis.title = element_blank(), axis.text = element_blank(), axis.ticks = element_blank(),
      panel.grid = element_blank(),
      panel.border = element_rect(colour = 'black', fill = 'transparent', linewidth = 0.7),
      plot.title = element_text(size = 24, hjust = 0.5, face = 'bold'),
      legend.position = 'right',
      legend.key.width = unit(0.75, 'cm'), legend.key.height = unit(0.75, 'cm'),
      legend.text = element_text(size = 18),
      legend.title = element_text(size = 22),
      plot.margin = unit(c(4, 4, 4, 4), 'mm')
    )
}

# ---- Main -------------------------------------------------------------------

main <- function() {
  grid_file <- file.path(output_dir,
    sprintf('pm25_premature_death_grid_%s_%s.csv', curve_name_sel, year_sel))
  if (!file.exists(grid_file)) stop('Grid output not found: ', grid_file, ' — run calculation first.')
  
  message('Reading population grid...')
  pop_dt <- read_population()
  
  message('Reading mortality grid output...')
  mort_dt <- fread(grid_file)
  mort_dt <- mort_dt[Year == year_sel & curve_name == curve_name_sel &
                     urarea %in% urarea_levels & Mort >= 0]
  
  # Merge mortality into population grid
  grid_dt <- merge(pop_dt, mort_dt[, .(X_Lon, Y_Lat, urarea, concentration, MortRate_PM25, Mort)],
                   by = c('X_Lon', 'Y_Lat', 'Year', 'urarea'), all.x = TRUE)
  grid_dt[is.na(Mort), Mort := 0]
  
  # Assign bins
  bin_labels <- names(death_colors)
  grid_dt[, Mort_bin := cut(Mort, breaks = death_breaks, labels = bin_labels,
                             include.lowest = TRUE, right = TRUE, ordered_result = TRUE)]
  
  # Load boundary shapefile (user must provide)
  if (shp_dir != '') {
    boundary <- st_read(shp_dir, quiet = TRUE)
    target_crs <- st_crs(boundary)
  } else {
    warning('No SHP_DIR set; using WGS84 / Plate Carree. Maps may look distorted.')
    boundary <- st_sfc(st_polygon(), crs = 4326)
    target_crs <- 4326
  }
  
  plot_dt <- prepare_plot_data(grid_dt, target_crs)
  
  legend_title <- expression(paste('PM'[2.5], '-related deaths (#/grid)'))
  
  for (area in urarea_levels) {
    sub <- plot_dt[plot_dt[['urarea']] == area, ]
    if (nrow(sub) == 0) next
    
    p <- plot_mortality_map(sub, boundary, legend_title)
    out_png <- file.path(output_dir,
      sprintf('pm25_premature_death_map_%s_%s_%s.png', curve_name_sel, year_sel, area))
    ggsave(out_png, p, width = 9.5, height = 7.2, dpi = 300)
    message('Wrote: ', out_png)
  }
  
  message('Done.')
}

main()
