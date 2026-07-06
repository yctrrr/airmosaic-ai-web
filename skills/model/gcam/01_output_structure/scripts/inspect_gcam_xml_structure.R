#!/usr/bin/env Rscript

# Inspect the GCAM BaseX XML tree directly, without Main_queries.xml.
# Use for discovering scenarios, regions, sectors, subsectors, and technologies.

options(stringsAsFactors = FALSE)

parse_args <- function(args) {
  out <- list(
    release_dir = Sys.getenv("GCAM_RELEASE_DIR", unset = NA_character_),
    output_dir = NA_character_,
    max_memory = Sys.getenv("GCAM_BASEX_MAX_MEMORY", unset = "1g")
  )
  for (arg in args) {
    if (grepl("^--release-dir=", arg)) {
      out$release_dir <- sub("^--release-dir=", "", arg)
    } else if (grepl("^--output-dir=", arg)) {
      out$output_dir <- sub("^--output-dir=", "", arg)
    } else if (grepl("^--max-memory=", arg)) {
      out$max_memory <- sub("^--max-memory=", "", arg)
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  out
}

script_path <- function() {
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(file_arg) == 0) return(normalizePath(".", winslash = "/", mustWork = TRUE))
  normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = TRUE)
}

check_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop("Missing required R package: ", pkg, call. = FALSE)
}

run_basex_csv <- function(query, db_path, db_name, classpath, max_memory) {
  tmp_output <- tempfile(fileext = ".csv")
  tmp_query <- tempfile(fileext = ".xq")
  on.exit(unlink(tmp_output), add = TRUE)
  on.exit(unlink(tmp_query), add = TRUE)
  writeLines(query, tmp_query)
  args <- c(
    "-cp", classpath,
    paste0("-Xmx", max_memory),
    paste0("-Dorg.basex.DBPATH=", db_path),
    "org.basex.BaseX",
    "-smethod=csv", "-scsv=header=yes",
    "-o", tmp_output,
    "-i", db_name,
    paste("RUN", tmp_query)
  )
  status <- system2("java", args = args)
  if (!identical(status, 0L)) stop("BaseX query failed with status ", status, call. = FALSE)
  data.table::fread(tmp_output, encoding = "UTF-8")
}

csv_query <- function(record_body) {
  paste0("let $dummy := 1 return document{ element csv { ", record_body, " } }")
}

args <- parse_args(commandArgs(TRUE))
check_package("data.table")
check_package("rgcam")

release_dir <- if (!is.na(args$release_dir) && nzchar(args$release_dir)) {
  normalizePath(args$release_dir, winslash = "/", mustWork = TRUE)
} else {
  stop("Set GCAM_RELEASE_DIR environment variable or pass --release-dir=")
}

output_dir <- if (!is.na(args$output_dir) && nzchar(args$output_dir)) {
  normalizePath(args$output_dir, winslash = "/", mustWork = FALSE)
} else {
  file.path(release_dir, "database_R", "derived", "xml_structure")
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

province_csv <- file.path(release_dir, "database_R", "Prov_code_china.csv")
db_path <- file.path(release_dir, "output")
db_name <- "database_basexdb"

if (!file.exists(province_csv)) stop("Province mapping not found: ", province_csv, call. = FALSE)
database_dir <- file.path(db_path, db_name)
if (!dir.exists(database_dir)) stop("BaseX database directory not found: ", database_dir, call. = FALSE)

province <- data.table::fread(province_csv, colClasses = "character", encoding = "UTF-8")
regions <- sort(unique(stats::na.omit(province$GCAM_name)))
region_list <- paste0("('", paste(regions, collapse = "','"), "')")
classpath <- rgcam:::DEFAULT.MICLASSPATH()

queries <- list(
  scenarios = csv_query("
    for $s in collection()/scenario
    return element record {
      element scenario { string($s/@name) },
      element date { string($s/@date) },
      element model_version { string($s/model-version/text()) },
      element top_child_types { string-join(distinct-values($s/world/*/@type), ';') }
    }
  "),

  province_top_level = csv_query(paste0("
    for $s in collection()/scenario
    for $r in $s/world/*[@type='region' and @name = ", region_list, "]
    for $child in $r/*
    group by $scenario := string($s/@name), $region := string($r/@name),
      $child_type := string($child/@type), $child_name := string($child/@name),
      $node_name := name($child)
    order by $scenario, $region, $child_type, $child_name
    return element record {
      element scenario { $scenario },
      element region { $region },
      element child_type { $child_type },
      element child_name { $child_name },
      element xml_node { $node_name },
      element count { count($child) }
    }
  ")),

  industrial_sector_tree = csv_query(paste0("
    for $s in collection()/scenario
    for $r in $s/world/*[@type='region' and @name = ", region_list, "]
    for $sec in $r/*[@type='sector']
    where $sec/@name = ('cement','iron and steel','chemical','aluminum','paper','food processing','other industry','ammonia')
    for $sub in $sec/*[@type='subsector']
    for $tech in $sub/*[@type='technology']
    let $outputs := string-join(distinct-values($tech/*[@type='output']/@name), ';')
    let $inputs := string-join(distinct-values($tech/*[@type='input']/@name), ';')
    let $output_units := string-join(distinct-values($tech/*[@type='output']/physical-output/@unit), ';')
    let $years := string-join(distinct-values($tech/*[@type='output']/physical-output/@vintage), ';')
    return element record {
      element scenario { string($s/@name) },
      element region { string($r/@name) },
      element sector { string($sec/@name) },
      element subsector { string($sub/@name) },
      element technology { string($tech/@name) },
      element outputs { $outputs },
      element inputs { $inputs },
      element output_units { $output_units },
      element output_years { $years }
    }
  ")),

  industrial_cost_nodes = csv_query(paste0("
    for $s in collection()/scenario
    for $r in $s/world/*[@type='region' and @name = ", region_list, "]
    for $sec in $r/*[@type='sector']
    where $sec/@name = ('cement','iron and steel','chemical','aluminum','paper','food processing','other industry','ammonia')
    return element record {
      element scenario { string($s/@name) },
      element region { string($r/@name) },
      element sector { string($sec/@name) },
      element sector_cost_years { string-join(distinct-values($sec/cost/@year), ';') },
      element sector_cost_units { string-join(distinct-values($sec/cost/@unit), ';') },
      element sector_cost_count { count($sec/cost) },
      element physical_output_count { count($sec//physical-output) },
      element input_demand_count { count($sec//demand-physical) }
    }
  "))
)

for (nm in names(queries)) {
  out_file <- file.path(output_dir, paste0("inspect_", nm, ".csv"))
  cat("Running query:", nm, "->", out_file, "\n")
  result <- tryCatch(
    run_basex_csv(queries[[nm]], db_path, db_name, classpath, args$max_memory),
    error = function(e) { message("Query ", nm, " failed: ", e$message); return(NULL) }
  )
  if (!is.null(result)) {
    data.table::fwrite(result, out_file)
    cat("  rows:", nrow(result), "\n")
  }
}

cat("Done. Output in:", output_dir, "\n")
