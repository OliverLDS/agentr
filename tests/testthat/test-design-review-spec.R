test_that("build_design_review_data creates a complete review bundle", {
  spec <- .test_complete_agent_spec()

  review <- build_design_review_data(spec, review_id = "review_001")

  expect_true(inherits(review, "DesignReviewSpec"))
  validate_design_review_spec(review)

  bundle <- review$to_list()
  expect_equal(bundle$review_id, "review_001")
  expect_equal(bundle$agent_name, "macro-fixture-agent")
  expect_equal(length(bundle$workflow_graph$nodes), 2L)
  expect_equal(length(bundle$workflow_graph$edges), 1L)
  expect_equal(length(bundle$memory_schema$fields), 4L)
  expect_equal(length(bundle$narrative_knowledge$items), 1L)
  expect_true("feedback_schema" %in% names(bundle))
  expect_equal(bundle$metadata$autonomy_stage, "human_in_loop")
  expect_true("interface_spec" %in% names(bundle$metadata))
  expect_true("state_spec" %in% names(bundle$metadata))
})

test_that("build_design_review_data includes proposal-state snapshots", {
  spec <- .test_complete_agent_spec()

  workflow_state <- WorkflowProposalState$new(approved_workflow = spec$workflow)
  memory_state <- MemoryProposalState$new(approved_memory_spec = spec$memory_spec)
  knowledge_state <- KnowledgeProposalState$new(approved_knowledge_spec = spec$knowledge_spec)
  graph_state <- KnowledgeGraphProposalState$new(
    approved_graph = knowledge_graph_from_spec(spec$knowledge_spec)
  )

  review <- build_design_review_data(
    spec,
    workflow_state = workflow_state,
    memory_state = memory_state,
    knowledge_state = knowledge_state,
    graph_state = graph_state
  )
  bundle <- review$to_list()

  expect_true(is.list(bundle$proposal_states$workflow))
  expect_true(is.list(bundle$proposal_states$memory))
  expect_true(is.list(bundle$proposal_states$knowledge))
  expect_true(is.list(bundle$proposal_states$graph))
  expect_equal(length(bundle$proposal_states$memory$approved_memory_spec$fields), 4L)
  expect_gt(length(bundle$proposal_states$graph$approved_graph$nodes), 0L)
})

test_that("design feedback helpers validate and parse structured feedback", {
  item <- design_feedback_item(
    target = "memory_schema",
    field = "agent.memory.state",
    issue = "State names are unclear.",
    suggestion = "Separate lifecycle_state from task_state.",
    severity = "medium",
    item_id = "current_task_context"
  )

  expect_true(inherits(item, "agentr_design_feedback_item"))
  validate_design_feedback(item)

  parsed <- parse_design_feedback_json(jsonlite::toJSON(
    list(feedback = list(unclass(item))),
    auto_unbox = TRUE
  ))

  expect_equal(length(parsed), 1L)
  expect_equal(parsed[[1]]$target, "memory_schema")
  expect_equal(parsed[[1]]$severity, "medium")

  parsed_many <- parse_design_feedback_json(jsonlite::toJSON(
    list(feedback = list(
      unclass(item),
      unclass(design_feedback_item(
        target = "workflow_node",
        field = "workflow.nodes.node_interpret.label",
        issue = "Node label is too broad.",
        suggestion = "Separate interpretation from review.",
        severity = "low"
      ))
    )),
    auto_unbox = TRUE
  ))
  expect_equal(length(parsed_many), 2L)
  expect_equal(parsed_many[[2]]$target, "workflow_node")
})

test_that("design feedback rejects unknown targets and malformed items", {
  expect_error(
    design_feedback_item(
      target = "runtime_executor",
      field = "agent.runtime",
      issue = "Unsupported target.",
      suggestion = "Use a design target.",
      severity = "medium"
    ),
    "workflow_graph"
  )

  expect_error(
    validate_design_feedback(list(
      target = "workflow_node",
      field = "",
      issue = "Missing field.",
      suggestion = "Add a field path.",
      severity = "low"
    )),
    "`field` must be a non-empty string"
  )
})
