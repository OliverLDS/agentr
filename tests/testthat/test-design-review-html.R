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

test_that("design_review_html wraps workflow graph labels without truncation", {
  long_label <- "Select the most appropriate chart type for the economic analysis and document why alternatives were rejected"
  workflow <- new_workflow_spec(
    nodes = workflow_node("node_long", long_label),
    edges = .empty_workflow_edges(),
    task = "Long label review"
  )
  html <- design_review_html(workflow, title = "Long label review")

  expect_false(grepl("slice(0,24)", html, fixed = TRUE))
  expect_true(grepl("wrapSvgText", html, fixed = TRUE))
  expect_true(grepl("<tspan", html, fixed = TRUE))
  expect_true(grepl("_cy=n._y+n._h/2", html, fixed = TRUE))
  expect_true(grepl("overflow-wrap:anywhere", html, fixed = TRUE))
  expect_true(grepl(long_label, html, fixed = TRUE))
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
