test_that("KnowledgeSpec initializes, validates, and round-trips", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  ks <- KnowledgeSpec$new()
  expect_true(inherits(ks, "KnowledgeSpec"))
  expect_equal(length(ks$items), 0L)

  item <- list(
    id = "ki_yoy_macro_001",
    type = "heuristic",
    raw_statement = "Use YoY when monthly macro data is noisy.",
    normalized_statement = "For noisy monthly macro indicators, YoY is often better for medium-term interpretation.",
    domain = "macro_analysis",
    conditions = c("monthly macro data"),
    exceptions = c("short-term shock timing"),
    confidence = "medium",
    review = list(status = "approved")
  )
  ks$add_item(item)
  expect_equal(length(ks$items), 1L)
  expect_equal(ks$get_item("ki_yoy_macro_001")$type, "heuristic")

  expect_error(
    ks$add_item(item),
    "Duplicate id"
  )

  expect_error(
    validate_knowledge_item(modifyList(item, list(review = list(status = "bad_status")))),
    "should be one of"
  )

  save_knowledge_spec(ks, path)
  loaded <- load_knowledge_spec(path)
  expect_true(inherits(loaded, "KnowledgeSpec"))
  expect_equal(length(loaded$items), 1L)
})
