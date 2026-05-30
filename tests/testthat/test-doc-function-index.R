test_that("function index names every exported package object", {
  exports <- getNamespaceExports("agentr")
  index <- paste(readLines(test_path("..", "..", "docs", "function_index.md")), collapse = "\n")

  missing <- exports[!vapply(
    exports,
    function(export) {
      grepl(paste0("`", export, "`"), index, fixed = TRUE) ||
        grepl(paste0("`", export, "()`"), index, fixed = TRUE)
    },
    logical(1)
  )]

  expect_equal(missing, character())
})
