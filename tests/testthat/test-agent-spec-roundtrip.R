test_that("complete AgentSpec fixture round-trips through explicit persistence", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  spec <- .test_complete_agent_spec()
  save_agent_spec(spec, path)
  loaded <- load_agent_spec(path)

  expect_true(inherits(loaded, "AgentSpec"))
  expect_equal(loaded$agent_name, "macro-fixture-agent")
  expect_equal(loaded$selected_subsystems(), c("rwm", "pg", "ae", "la"))
  expect_equal(length(loaded$knowledge_spec$items), 1L)
  expect_equal(loaded$knowledge_spec$get_item("ki_yoy_macro_001")$review$status, "approved")
  expect_equal(loaded$state_spec$lifecycle_state$allowed_values[[1]], "idle")
  expect_true(isTRUE(loaded$state_spec$task_state$persistent))
  expect_equal(loaded$interface_spec$files$inputs, "data/macro/latest.csv")
  expect_equal(loaded$interface_spec$tools$r_packages, c("readr", "ggplot2"))
  expect_equal(loaded$autonomy_spec$default_stage, "human_in_loop")
  expect_equal(loaded$autonomy_stage, "human_in_loop")
  expect_equal(loaded$workflow$nodes$knowledge_refs[[2]], "ki_yoy_macro_001")
  expect_true(isTRUE(loaded$workflow$nodes$trace_required[[2]]))
})

test_that("complete AgentSpec fixture can feed implementation prompt knowledge selection", {
  spec <- .test_complete_agent_spec()

  prompt <- build_implementation_prompt(
    spec,
    language = "R",
    format = "json",
    include_knowledge = TRUE,
    knowledge_scope = "referenced"
  )

  expect_true(grepl("\"knowledge\"", prompt, fixed = TRUE))
  expect_true(grepl("ki_yoy_macro_001", prompt, fixed = TRUE))
  expect_true(grepl("For noisy monthly macro indicators", prompt, fixed = TRUE))
})
