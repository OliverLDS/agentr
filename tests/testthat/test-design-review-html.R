test_that("design_review_html returns standalone review page", {
  spec <- .test_complete_agent_spec()
  html <- design_review_html(spec, title = "Fixture review")

  expect_true(is.character(html))
  expect_length(html, 1L)
  expect_true(grepl("Fixture review", html, fixed = TRUE))
  expect_true(grepl("agentr-review-data", html, fixed = TRUE))
  expect_true(grepl("Workflow graph", html, fixed = TRUE))
  expect_true(grepl("Structured feedback", html, fixed = TRUE))
  expect_true(grepl("memory_schema", html, fixed = TRUE))
  expect_false(grepl("https://", html, fixed = TRUE))
  expect_false(grepl("http://", html, fixed = TRUE))
})

test_that("export_design_review_html writes a file", {
  spec <- .test_complete_agent_spec()
  path <- tempfile(fileext = ".html")

  out <- export_design_review_html(spec, path, title = "Exported review")

  expect_equal(out, normalizePath(path, mustWork = FALSE))
  expect_true(file.exists(path))
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Exported review", txt, fixed = TRUE))
  expect_true(grepl("download JSON", txt, ignore.case = TRUE))
})
