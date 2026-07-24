suppressWarnings(suppressPackageStartupMessages({
  library(DBI)
  library(dplyr)
  library(ggplot2)
}))

read_crop_sources <- function(data_dir = here::here("data")) {
  sources <- list(
    crop = read.csv(file.path(data_dir, "annual_crop.csv"), stringsAsFactors = FALSE),
    daily_fx = read.csv(file.path(data_dir, "daily_fx.csv"), stringsAsFactors = FALSE),
    monthly_fx = read.csv(file.path(data_dir, "monthly_fx.csv"), stringsAsFactors = FALSE),
    prices = read.csv(file.path(data_dir, "monthly_farm_prices.csv"), stringsAsFactors = FALSE)
  )

  sources$crop$YEAR <- as.Date(sources$crop$YEAR)
  sources$crop$YEAR_NUMBER <- as.integer(format(sources$crop$YEAR, "%Y"))
  sources$daily_fx$DATE <- as.Date(sources$daily_fx$DATE)
  sources$monthly_fx$DATE <- as.Date(sources$monthly_fx$DATE)
  sources$prices$DATE <- as.Date(sources$prices$DATE)
  validate_crop_sources(sources)
  sources
}

validate_crop_sources <- function(sources) {
  expected <- list(
    crop = c("CD_ID", "YEAR", "CROP_TYPE", "GEO", "SEEDED_AREA", "HARVESTED_AREA", "PRODUCTION", "AVG_YIELD"),
    daily_fx = c("DFX_ID", "DATE", "FXUSDCAD"),
    monthly_fx = c("DFX_ID", "DATE", "FXUSDCAD"),
    prices = c("CD_ID", "DATE", "CROP_TYPE", "GEO", "PRICE_PRERMT")
  )

  for (table_name in names(expected)) {
    missing_columns <- setdiff(expected[[table_name]], names(sources[[table_name]]))
    if (length(missing_columns) > 0) {
      stop(table_name, " is missing columns: ", paste(missing_columns, collapse = ", "))
    }
    if (nrow(sources[[table_name]]) == 0) {
      stop(table_name, " contains no records")
    }
  }

  if (anyDuplicated(sources$crop$CD_ID)) {
    stop("annual crop identifiers must be unique")
  }
  invisible(TRUE)
}

build_crop_database <- function(sources, database = tempfile(fileext = ".sqlite")) {
  connection <- dbConnect(RSQLite::SQLite(), database)
  dbWriteTable(connection, "crop_data", sources$crop, overwrite = TRUE)
  dbWriteTable(connection, "daily_fx", sources$daily_fx, overwrite = TRUE)
  dbWriteTable(connection, "monthly_fx", sources$monthly_fx, overwrite = TRUE)
  dbWriteTable(connection, "farm_prices", sources$prices, overwrite = TRUE)
  connection
}

top_crop_yields <- function(connection, geography, year, limit = 5L) {
  query <- "
    SELECT CROP_TYPE, ROUND(AVG(AVG_YIELD), 1) AS average_yield
    FROM crop_data
    WHERE GEO = ? AND YEAR_NUMBER = ?
    GROUP BY CROP_TYPE
    ORDER BY average_yield DESC
    LIMIT ?"
  dbGetQuery(connection, query, params = list(geography, as.integer(year), as.integer(limit)))
}

recent_canola_prices <- function(connection, geography = "Saskatchewan", limit = 12L) {
  query <- "
    SELECT
      p.DATE,
      p.PRICE_PRERMT AS price_cad_per_tonne,
      fx.FXUSDCAD,
      ROUND(p.PRICE_PRERMT / fx.FXUSDCAD, 2) AS price_usd_per_tonne
    FROM farm_prices p
    INNER JOIN monthly_fx fx ON p.DATE = fx.DATE
    WHERE p.CROP_TYPE = 'Canola' AND p.GEO = ?
    ORDER BY p.DATE DESC
    LIMIT ?"
  result <- dbGetQuery(connection, query, params = list(geography, as.integer(limit)))
  result$DATE <- as.Date(result$DATE, origin = "1970-01-01")
  result
}

national_crop_trends <- function(connection, crops = c("Barley", "Rye", "Wheat")) {
  placeholders <- paste(rep("?", length(crops)), collapse = ",")
  query <- paste0(
    "SELECT YEAR, CROP_TYPE, PRODUCTION
     FROM crop_data
     WHERE GEO = 'Canada' AND CROP_TYPE IN (", placeholders, ")
     ORDER BY YEAR, CROP_TYPE"
  )
  result <- dbGetQuery(connection, query, params = as.list(crops))
  result$YEAR <- as.Date(result$YEAR, origin = "1970-01-01")
  result
}

plot_crop_trends <- function(data, language = c("en", "es")) {
  language <- match.arg(language)
  labels <- if (language == "en") {
    c(title = "Canadian crop production over time", x = "Year", y = "Production (metric tonnes)", color = "Crop")
  } else {
    c(title = "Producción agrícola canadiense a través del tiempo", x = "Año", y = "Producción (toneladas métricas)", color = "Cultivo")
  }

  ggplot(data, aes(YEAR, PRODUCTION, color = CROP_TYPE)) +
    geom_line(linewidth = 0.8) +
    scale_y_continuous(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
    scale_color_viridis_d(end = 0.85) +
    labs(title = labels[["title"]], x = labels[["x"]], y = labels[["y"]], color = labels[["color"]]) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"), legend.position = "bottom")
}
