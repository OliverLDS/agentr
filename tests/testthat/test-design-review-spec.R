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

test_that("build_design_review_data supports workflow-only and knowledge-only inputs", {
  spec <- .test_complete_agent_spec()

  workflow_review <- build_design_review_data(spec$workflow)
  expect_true(inherits(workflow_review, "DesignReviewSpec"))
  expect_equal(length(workflow_review$workflow_graph$nodes), 2L)
  expect_equal(length(workflow_review$memory_schema$fields), 0L)

  knowledge_review <- build_design_review_data(spec$knowledge_spec)
  expect_true(inherits(knowledge_review, "DesignReviewSpec"))
  expect_equal(length(knowledge_review$narrative_knowledge$items), 1L)
  expect_equal(length(knowledge_review$workflow_graph$nodes), 0L)
})

test_that("new_design_review_spec and design review persistence round trip", {
  review <- new_design_review_spec(review_id = "review_empty")
  expect_true(inherits(review, "DesignReviewSpec"))

  path <- tempfile(fileext = ".rds")
  save_design_review_spec(review, path)
  loaded <- load_design_review_spec(path)

  expect_true(inherits(loaded, "DesignReviewSpec"))
  expect_equal(loaded$review_id, "review_empty")
})

test_that("build_design_review_data includes proposal-state snapshots", {
  spec <- .test_complete_agent_spec()

  workflow_state <- WorkflowProposalState$new(approved_workflow = spec$workflow)
  memory_state <- MemoryProposalState$new(approved_memory_spec = spec$memory_spec)
  knowledge_state <- KnowledgeProposalState$new(approved_knowledge_spec = spec$knowledge_spec)

  review <- build_design_review_data(
    spec,
    workflow_state = workflow_state,
    memory_state = memory_state,
    knowledge_state = knowledge_state
  )
  bundle <- review$to_list()

  expect_true(is.list(bundle$proposal_states$workflow))
  expect_true(is.list(bundle$proposal_states$memory))
  expect_true(is.list(bundle$proposal_states$knowledge))
  expect_null(bundle$proposal_states$graph)
  expect_equal(length(bundle$proposal_states$memory$approved_memory_spec$fields), 4L)
})

test_that("design feedback helpers validate and parse structured feedback", {
  item <- design_feedback_item(
    target = "memory_schema",
    field = "agent.memory.state",
    issue = "State names are unclear.",
    suggestion = "Separate lifecycle_state from task_state.",
    severity = "medium",
    issue_type = "unclear",
    target_id = "current_task_context",
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
  expect_equal(parsed[[1]]$issue_type, "unclear")
  expect_equal(parsed[[1]]$severity, "medium")

  parsed_many <- parse_design_feedback_json(jsonlite::toJSON(
    list(feedback = list(
      unclass(item),
      unclass(design_feedback_item(
        target = "workflow_node",
        field = "workflow.nodes.node_interpret.label",
        issue = "Node label is too broad.",
        suggestion = "Separate interpretation from review.",
        severity = "low",
        issue_type = "too_broad"
      ))
    )),
    auto_unbox = TRUE
  ))
  expect_equal(length(parsed_many), 2L)
  expect_equal(parsed_many[[2]]$target, "workflow_node")
})

test_that("design feedback rejects unknown targets, issue types, severities, and malformed items", {
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
    design_feedback_item(
      target = "workflow_node",
      field = "workflow.nodes.node_interpret",
      issue = "Bad issue type.",
      suggestion = "Use a supported issue type.",
      severity = "medium",
      issue_type = "arbitrary_code"
    ),
    "missing"
  )

  expect_error(
    design_feedback_item(
      target = "workflow_node",
      field = "workflow.nodes.node_interpret",
      issue = "Bad severity.",
      suggestion = "Use a supported severity.",
      severity = "critical"
    ),
    "low"
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

test_that("design feedback warns on missing target ids when review spec is supplied", {
  review <- build_design_review_data(.test_complete_agent_spec())
  item <- design_feedback_item(
    target = "workflow_node",
    target_id = "missing_node",
    field = "workflow.nodes.missing_node",
    issue_type = "missing",
    issue = "Node is missing.",
    suggestion = "Add or rename the node.",
    severity = "medium"
  )

  expect_warning(
    validate_design_feedback(item, review_spec = review),
    "target id not found"
  )
})

test_that("design feedback persistence round trips", {
  item <- design_feedback_item(
    target = "agent_summary",
    target_id = "agent_summary",
    field = "agent.summary",
    issue_type = "unclear",
    issue = "Summary is vague.",
    suggestion = "State the supported task boundary.",
    severity = "low"
  )
  path <- tempfile(fileext = ".rds")
  save_design_feedback(list(item), path)
  loaded <- load_design_feedback(path)

  expect_equal(length(loaded), 1L)
  expect_equal(loaded[[1]]$target, "agent_summary")
})
