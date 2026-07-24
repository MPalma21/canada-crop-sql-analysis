dir.create("data", showWarnings = FALSE, recursive = TRUE)

sources <- c(
  annual_crop = "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBM-RP0203EN-SkillsNetwork/labs/Practice%20Assignment/Annual_Crop_Data.csv",
  daily_fx = "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBM-RP0203EN-SkillsNetwork/labs/Practice%20Assignment/Daily_FX.csv",
  monthly_fx = "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBM-RP0203EN-SkillsNetwork/labs/Final%20Project/Monthly_FX.csv",
  monthly_farm_prices = "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBM-RP0203EN-SkillsNetwork/labs/Final%20Project/Monthly_Farm_Prices.csv"
)

for (source_name in names(sources)) {
  destination <- file.path("data", paste0(source_name, ".csv"))
  download.file(sources[[source_name]], destination, mode = "wb", quiet = TRUE)
  if (file.info(destination)$size == 0) {
    stop("Downloaded an empty file: ", destination)
  }
}

writeLines(
  c(
    paste("snapshot_date:", Sys.Date()),
    paste(names(sources), sources, sep = ": ")
  ),
  file.path("data", "SOURCES.txt")
)

