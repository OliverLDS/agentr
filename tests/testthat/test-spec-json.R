test_that("workflow specs round-trip through JSON", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)

  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node(
        id = "node_1",
        label = "Draft",
        knowledge_refs = c("ki_1"),
        input_schema = list(type = "object"),
        output_schema = list(type = "object")
      ),
      workflow_node(
        id = "node_2",
        label = "Review",
        subworkflow_ref = "subtasks/node_2/docs/workflow_spec.json"
      )
    ),
    edges = workflow_edge("node_1", "node_2", relation = "depends_on"),
    task = "JSON round-trip"
  )

  save_workflow_spec(workflow, path)
  loaded <- load_workflow_spec(path)

  expect_s3_class(loaded, "agentr_workflow_spec")
  expect_equal(loaded$task, "JSON round-trip")
  expect_equal(loaded$nodes$knowledge_refs[[1]], c("ki_1"))
  expect_equal(loaded$nodes$subworkflow_ref[[2]], "subtasks/node_2/docs/workflow_spec.json")
  expect_equal(loaded$nodes$input_schema[[1]]$type, "object")
  expect_equal(loaded$nodes$output_schema[[1]]$type, "object")
})

test_that("memory specs round-trip through JSON", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)

  spec <- MemorySpec$new(fields = list(
    memory_field(
      id = "state_task",
      label = "Task state",
      memory_type = "context",
      description = "Current task state",
      schema = list(type = "object"),
      persistence = "session"
    )
  ))

  save_memory_spec(spec, path)
  loaded <- load_memory_spec(path)

  expect_s3_class(loaded, "MemorySpec")
  expect_equal(loaded$get_field("state_task")$label, "Task state")
  expect_equal(loaded$get_field("state_task")$schema$type, "object")
})

test_that("knowledge specs round-trip through JSON with nested graph knowledge", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)

  graph <- new_knowledge_graph_spec(
    nodes = rbind(
      knowledge_graph_node("act_r", "ACT-R", node_type = "concept", memory_type = "semantic"),
      knowledge_graph_node("cognitive_architecture", "cognitive architecture", node_type = "concept", memory_type = "semantic")
    ),
    edges = knowledge_graph_edge(
      "act_r",
      "cognitive_architecture",
      relation = "is_a",
      relation_type = "is_a",
      memory_type = "semantic"
    ),
    metadata = list(graph_mode = "curated")
  )

  spec <- KnowledgeSpec$new(
    items = list(list(
      id = "ki_actr_001",
      type = "concept",
      raw_statement = "ACT-R is a cognitive architecture.",
      normalized_statement = "ACT-R is a cognitive architecture.",
      review = list(status = "approved")
    )),
    graph = graph,
    vector_refs = list(external_store = list(store = "pinecone", collection = "agent_knowledge"))
  )

  save_knowledge_spec(spec, path)
  loaded <- load_knowledge_spec(path)

  expect_s3_class(loaded, "KnowledgeSpec")
  expect_s3_class(loaded$graph, "agentr_knowledge_graph_spec")
  expect_equal(loaded$list_items()[[1]]$id, "ki_actr_001")
  expect_equal(loaded$graph$edges$relation[[1]], "is_a")
  expect_equal(loaded$graph$metadata$graph_mode, "curated")
})

test_that("knowledge graph specs round-trip through JSON", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)

  graph <- new_knowledge_graph_spec(
    nodes = rbind(
      knowledge_graph_node(
        id = "react",
        label = "ReAct",
        node_type = "concept",
        memory_type = "procedural",
        review = list(status = "approved"),
        scope = list(domain = "agent_methods")
      ),
      knowledge_graph_node(
        id = "observe_decide_act",
        label = "observe-decide-act",
        node_type = "concept",
        memory_type = "procedural",
        review = list(status = "approved")
      )
    ),
    edges = knowledge_graph_edge(
      "react",
      "observe_decide_act",
      relation = "implements_part_of",
      relation_type = "implements_part_of",
      memory_type = "procedural",
      review = list(status = "approved")
    ),
    metadata = list(graph_mode = "curated")
  )

  save_knowledge_graph_spec(graph, path)
  loaded <- load_knowledge_graph_spec(path)

  expect_s3_class(loaded, "agentr_knowledge_graph_spec")
  expect_equal(loaded$nodes$id[[1]], "react")
  expect_equal(loaded$edges$relation[[1]], "implements_part_of")
  expect_equal(loaded$metadata$graph_mode, "curated")
})
