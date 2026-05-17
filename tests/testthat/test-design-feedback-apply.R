test_that("preview_design_feedback is non-mutating", {
  scaffolder <- Scaffolder$new()
  scaffolder$evaluate_task("Review fixture workflow")
  scaffolder$decompose_task(
    nodes = list(list(id = "node_a", label = "Review node")),
    edges = list()
  )
  before <- length(scaffolder$interaction_log)
  item <- design_feedback_item(
    target = "workflow_node",
    target_id = "node_a",
    field = "workflow.nodes.node_a",
    issue_type = "unclear",
    issue = "Node label is unclear.",
    suggestion = "Rename it with a concrete action.",
    severity = "medium"
  )

  preview <- preview_design_feedback(scaffolder, item)

  expect_equal(length(scaffolder$interaction_log), before)
  expect_false(preview$mutates)
  expect_equal(preview$action_count, 1L)
  expect_equal(preview$actions[[1]]$route, "scaffolder_node_review")
})

test_that("apply_design_feedback routes workflow-node feedback through review_node", {
  scaffolder <- Scaffolder$new()
  scaffolder$evaluate_task("Review fixture workflow")
  scaffolder$decompose_task(
    nodes = list(list(id = "node_a", label = "Review node")),
    edges = list()
  )
  item <- design_feedback_item(
    target = "workflow_node",
    target_id = "node_a",
    field = "workflow.nodes.node_a.implementation_hint",
    issue_type = "implementation_gap",
    issue = "Implementation hint is missing.",
    suggestion = "Specify expected R output.",
    severity = "medium"
  )

  out <- apply_design_feedback(scaffolder, item)

  expect_identical(out, scaffolder)
  expect_equal(scaffolder$workflow$nodes$review_status[[1]], "needs_revision")
  expect_true(grepl("Implementation hint is missing", scaffolder$workflow$nodes$review_notes[[1]], fixed = TRUE))
  expect_equal(length(scaffolder$workflow$metadata$design_feedback), 1L)
})

test_that("apply_design_feedback preserves memory feedback as design discussion", {
  scaffolder <- Scaffolder$new()
  scaffolder$evaluate_task("Review memory schema")
  item <- design_feedback_item(
    target = "memory_schema",
    target_id = "current_task_context",
    field = "memory.fields.current_task_context",
    issue_type = "too_broad",
    issue = "Memory field mixes lifecycle and task state.",
    suggestion = "Split lifecycle_state and task_state.",
    severity = "high"
  )

  apply_design_feedback(scaffolder, item)

  expect_equal(length(scaffolder$workflow$metadata$design_feedback), 1L)
  expect_true(any(vapply(
    scaffolder$interaction_log,
    function(x) identical(x$type, "apply_design_feedback"),
    logical(1)
  )))
})
