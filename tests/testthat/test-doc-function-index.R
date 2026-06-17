test_that("function index names every exported package object", {
  exports <- getNamespaceExports("agentr")
  index_path <- test_path("..", "..", "docs", "function_index.md")
  skip_if_not(file.exists(index_path), "docs/function_index.md is not included in built-package checks")

  index <- paste(readLines(index_path), collapse = "\n")

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
