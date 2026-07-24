source(here::here("R", "analysis.R"))

test_that("snapshots have the expected schemas", {
  sources <- read_crop_sources()
  expect_true(nrow(sources$crop) > 100)
  expect_true(nrow(sources$prices) > 100)
  expect_s3_class(sources$crop$YEAR, "Date")
  expect_s3_class(sources$monthly_fx$DATE, "Date")
})

test_that("database queries return plausible results", {
  sources <- read_crop_sources()
  connection <- build_crop_database(sources)
  on.exit(DBI::dbDisconnect(connection), add = TRUE)

  yields <- top_crop_yields(connection, "Saskatchewan", 2000)
  prices <- recent_canola_prices(connection)
  trends <- national_crop_trends(connection)

  expect_true(nrow(yields) > 0)
  expect_true(all(yields$average_yield >= 0))
  expect_true(nrow(prices) > 0)
  expect_true(all(prices$price_usd_per_tonne > 0))
  expect_true(nrow(trends) > 0)
})

test_that("validation rejects missing columns", {
  broken <- list(
    crop = data.frame(CD_ID = 1),
    daily_fx = data.frame(),
    monthly_fx = data.frame(),
    prices = data.frame()
  )
  expect_error(validate_crop_sources(broken), "missing columns")
})

