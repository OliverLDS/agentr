test_that("fetch_rss returns a data frame with expected columns", {
  df <- fetch_rss("arXiv AI")
  expect_s3_class(df, "data.frame")
  expect_true(all(c("title", "link", "content", "pubDate") %in% names(df)))
})

test_that("fetch_fred_series parses numeric data", {
  config <- tool_set_config("fred")
  df <- fetch_fred_series("GDP", config)
  expect_s3_class(df, "data.frame")
  expect_type(df$value, "double")
  expect_true("date" %in% names(df))
})