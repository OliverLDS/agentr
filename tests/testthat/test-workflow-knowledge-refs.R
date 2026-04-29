test_that("workflow nodes can carry knowledge references and implementation prompt includes referenced approved knowledge", {
  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node("node_1", "Interpret market move", knowledge_refs = c("ki_001")),
      workflow_node("node_2", "Write report")
    ),
    edges = workflow_edge("node_1", "node_2"),
    task = "Knowledge-linked workflow"
  )
  expect_equal(workflow$nodes$knowledge_refs[[1]], "ki_001")

  ks <- KnowledgeSpec$new(items = list(list(
    id = "ki_001",
    type = "heuristic",
    raw_statement = "Use YoY when noise is high.",
    normalized_statement = "Use YoY for noisy monthly macro series.",
    review = list(status = "approved")
  )))

  expect_warning(
    validate_workflow_spec(workflow, knowledge_spec = KnowledgeSpec$new()),
    "missing knowledge items"
  )
  expect_silent(validate_workflow_spec(workflow, knowledge_spec = ks))

  spec <- AgentSpec$new(
    task = "Knowledge-linked workflow",
    agent_name = "macro-agent",
    workflow = workflow,
    knowledge_spec = ks
  )

  prompt <- build_implementation_prompt(spec, language = "R")
  expect_true(grepl("\"knowledge\"", prompt, fixed = TRUE))
  expect_true(grepl("\"ki_001\"", prompt, fixed = TRUE))
})

