#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
})

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x) || x == "") y else x

script_file <- sub("^--file=", "", commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))][1] %||% "")
script_dir <- if (nchar(script_file) > 0) dirname(script_file) else "."

out_dir <- Sys.getenv("UNIT_PRICE_OUT_DIR",
  unset = Sys.getenv("AIRMOSAIC_LOCAL_WORKSPACE",
    unset = file.path(script_dir, "output")))

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

parse_arg <- function(flag, default) {
  args <- commandArgs(trailingOnly = TRUE)
  hit <- which(args == flag)
  if (length(hit) == 0 || hit[1] == length(args)) return(default)
  trimws(strsplit(args[hit[1] + 1], ",", fixed = TRUE)[[1]])
}

default_sectors <- c("cement", "coke", "iron and steel")
default_scenarios <- character(0)
years <- c(2021L, 2035L)

sectors <- parse_arg("--sectors", default_sectors)
scenarios <- parse_arg("--scenarios", default_scenarios)
input_csv <- parse_arg("--input-csv", file.path(out_dir, "market_sector_rows.csv"))

weighted_mean <- function(price, quantity) {
  ok <- !is.na(price) & !is.na(quantity)
  if (!any(ok)) return(NA_real_)
  w <- pmax(quantity[ok], 0)
  p <- price[ok]
  if (sum(w) <= 1e-12) return(mean(p, na.rm = TRUE))
  sum(p * w) / sum(w)
}

stopifnot(file.exists(input_csv))

raw <- read_csv(input_csv, show_col_types = FALSE)

plot_data <- raw %>%
  filter(
    source == "sector_cost",
    !region %in% c("China", "Global"),
    sector %in% sectors,
    year %in% years
  ) %>%
  mutate(
    year = as.integer(year),
    price = as.numeric(price),
    quantity = as.numeric(quantity),
    year_label = factor(as.character(year), levels = as.character(years))
  )

if (length(scenarios) > 0) {
  plot_data <- plot_data %>% filter(scenario %in% scenarios)
}

if (nrow(plot_data) == 0) {
  stop("No plot data found. Check sector/scenario names.")
}

scenario_labels <- plot_data %>%
  distinct(scenario) %>%
  mutate(scenario_label = scenario) %>%
  { setNames(.$scenario_label, .$scenario) }

mean_data <- plot_data %>%
  group_by(scenario, sector, year, year_label) %>%
  summarise(
    weighted_price = weighted_mean(price, quantity),
    quantity_sum = sum(quantity, na.rm = TRUE),
    province_count = n_distinct(region),
    .groups = "drop"
  )

arrow_data <- mean_data %>%
  select(scenario, sector, year, weighted_price) %>%
  tidyr::pivot_wider(names_from = year, values_from = weighted_price,
                      names_prefix = "price_") %>%
  mutate(
    pct_change = 100 * (.data[[paste0("price_", years[2])]] -
      .data[[paste0("price_", years[1])]]) /
      abs(.data[[paste0("price_", years[1])]]),
    y_label = pmax(.data[[paste0("price_", years[1])]],
                   .data[[paste0("price_", years[2])]], na.rm = TRUE) * 1.04
  )

year_colors <- c("#4C78A8", "#F58518")
names(year_colors) <- as.character(years)
x_shift <- c(-0.18, 0.18)
names(x_shift) <- as.character(years)

plot_data <- plot_data %>%
  mutate(x = as.numeric(factor(sector, levels = sectors)) +
    x_shift[as.character(year)])

mean_data <- mean_data %>%
  mutate(x = as.numeric(factor(sector, levels = sectors)) +
    x_shift[as.character(year)])

arrow_data <- arrow_data %>%
  mutate(
    x_start = as.numeric(factor(sector, levels = sectors)) + x_shift[as.character(years[1])],
    x_end = as.numeric(factor(sector, levels = sectors)) + x_shift[as.character(years[2])],
    y_start = .data[[paste0("price_", years[1])]],
    y_end = .data[[paste0("price_", years[2])]]
  )

p <- ggplot(plot_data, aes(x = x, y = price,
    group = interaction(sector, year_label),
    color = year_label, fill = year_label)) +
  geom_boxplot(width = 0.28, alpha = 0.42, linewidth = 0.45,
               outlier.alpha = 0.55, outlier.size = 1.4) +
  geom_segment(data = arrow_data,
    aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
    inherit.aes = FALSE,
    arrow = arrow(length = unit(0.18, "inches"), type = "open"),
    linewidth = 1.05, color = "#222222") +
  geom_point(data = mean_data, aes(x = x, y = weighted_price, fill = year_label),
    inherit.aes = FALSE, shape = 21, size = 3.8, stroke = 0.75, color = "black") +
  geom_text(data = arrow_data,
    aes(x = as.numeric(factor(sector, levels = sectors)),
        y = y_label, label = sprintf("%+.1f%%", pct_change)),
    inherit.aes = FALSE, fontface = "bold", size = 6, vjust = 0) +
  scale_x_continuous(breaks = seq_along(sectors), labels = sectors,
                     expand = expansion(mult = c(0.06, 0.08))) +
  scale_color_manual(values = year_colors, guide = "none") +
  scale_fill_manual(values = year_colors, name = NULL) +
  labs(title = paste0("Unit Price Change ", years[1], " to ", years[2]),
       x = NULL, y = "Unit price") +
  theme_classic(base_size = 17) +
  theme(
    plot.title = element_text(size = 26, hjust = 0.5, margin = margin(b = 14)),
    axis.text.x = element_text(size = 20, angle = 12, hjust = 1),
    axis.text.y = element_text(size = 18),
    legend.position = "top"
  )

if (length(unique(plot_data$scenario)) > 1) {
  p <- p + facet_wrap(~scenario, ncol = 1, scales = "free_y")
}

out_png <- file.path(out_dir,
  paste0("sector_change_", years[1], "_", years[2], ".png"))
ggsave(out_png, p, width = 13.5, height = max(7, 3 * length(unique(plot_data$scenario))), dpi = 300)

write_csv(mean_data, file.path(out_dir, "sector_change_weighted_mean.csv"))
message("Wrote plots to: ", out_dir)
