test_that("transitional ownership helpers and traces work", {
  workflow <- new_workflow_spec(
    nodes = workflow_node("node_1", "Judge breakout"),
    edges = .empty_workflow_edges(),
    task = "Transitional workflow"
  )

  workflow <- mark_node_human_owned(
    workflow,
    node_id = "node_1",
    reason = "Human still judges whether the breakout is real.",
    target_automation_status = "llm_assisted",
    trace_required = TRUE
  )
  expect_equal(workflow$nodes$owner[[1]], "human")
  expect_equal(workflow$nodes$automation_status[[1]], "human_in_loop")
  expect_equal(workflow$nodes$target_automation_status[[1]], "llm_assisted")
  expect_true(isTRUE(workflow$nodes$trace_required[[1]]))

  workflow <- mark_node_agent_owned(workflow, "node_1")
  expect_equal(workflow$nodes$owner[[1]], "agent")
  expect_equal(workflow$nodes$automation_status[[1]], "agent_owned")

  jsonl <- tempfile(fileext = ".jsonl")
  rds <- tempfile(fileext = ".rds")
  on.exit(unlink(c(jsonl, rds)), add = TRUE)

  dtrace <- create_decision_trace(
    trace_id = "trace_001",
    agent_id = "macro-agent",
    workflow_node_id = "node_1",
    human_decision = "Use YoY instead of MoM.",
    rationale = "MoM is too noisy for this series."
  )
  append_decision_trace(dtrace, jsonl)
  append_decision_trace(dtrace, rds)
  expect_equal(length(read_decision_traces(jsonl)), 1L)
  expect_equal(length(read_decision_traces(rds)), 1L)

  rtrace <- create_reflection_trace(
    trace_id = "reflection_001",
    agent_id = "macro-agent",
    workflow_node_id = "node_1",
    reflection = "This judgment is reusable as a future rule."
  )
  append_reflection_trace(rtrace, jsonl)
  expect_equal(length(read_reflection_traces(jsonl)), 2L)
})

