test_that("workflow specs round-trip through JSON", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)

  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node(
        id = "node_1",
        label = "Draft",
        knowledge_refs = c("ki_1"),
        input_schema = list(type = "object", required = c("source")),
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
  expect_equal(loaded$nodes$input_schema[[1]]$required, "source")
  expect_equal(loaded$nodes$output_schema[[1]]$type, "object")
  saved_json <- paste(readLines(path, warn = FALSE), collapse = "")
  expect_true(grepl('"knowledge_refs":\\s*\\["ki_1"\\]', saved_json))
  expect_true(grepl('"required":\\s*\\["source"\\]', saved_json))

  scalar_path <- tempfile(fileext = ".json")
  on.exit(unlink(scalar_path), add = TRUE)
  writeLines(
    paste(
      '{',
      '"task":"Scalar JSON",',
      '"nodes":[{"id":"node_1","label":"Draft","knowledge_refs":"ki_scalar","input_schema":{"type":"object","required":"source"}}],',
      '"edges":[],',
      '"metadata":{}',
      '}',
      sep = ""
    ),
    scalar_path
  )
  scalar <- load_workflow_spec_json(scalar_path)
  expect_equal(scalar$nodes$knowledge_refs[[1]], "ki_scalar")
  expect_equal(scalar$nodes$input_schema[[1]]$required, "source")
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

test_that("workflow specs round-trip through YAML and normalize scalar arrays", {
  path <- tempfile(fileext = ".yaml")
  on.exit(unlink(path), add = TRUE)

  workflow <- new_workflow_spec(
    nodes = workflow_node(
      id = "node_1",
      label = "Draft",
      knowledge_refs = c("ki_1"),
      input_schema = list(type = "object", required = c("source"))
    ),
    edges = .empty_workflow_edges(),
    task = "YAML round-trip"
  )

  save_workflow_spec(workflow, path)
  loaded <- load_workflow_spec(path)

  expect_s3_class(loaded, "agentr_workflow_spec")
  expect_equal(loaded$nodes$knowledge_refs[[1]], "ki_1")
  expect_equal(loaded$nodes$input_schema[[1]]$required, "source")

  scalar_path <- tempfile(fileext = ".yaml")
  on.exit(unlink(scalar_path), add = TRUE)
  writeLines(c(
    "task: Scalar YAML",
    "nodes:",
    "- id: node_1",
    "  label: Draft",
    "  knowledge_refs: ki_scalar",
    "  input_schema:",
    "    type: object",
    "    required: source",
    "edges: []",
    "metadata: {}"
  ), scalar_path)

  scalar <- load_workflow_spec_yaml(scalar_path)
  expect_equal(scalar$nodes$knowledge_refs[[1]], "ki_scalar")
  expect_equal(scalar$nodes$input_schema[[1]]$required, "source")
})

test_that("memory, knowledge, and graph specs round-trip through YAML", {
  memory_path <- tempfile(fileext = ".yaml")
  knowledge_path <- tempfile(fileext = ".yaml")
  graph_path <- tempfile(fileext = ".yaml")
  on.exit(unlink(c(memory_path, knowledge_path, graph_path)), add = TRUE)

  memory <- MemorySpec$new(fields = list(
    memory_field(
      id = "state_task",
      label = "Task state",
      memory_type = "context",
      schema = list(type = "object", required = c("task_id"))
    )
  ))
  graph <- new_knowledge_graph_spec(
    nodes = knowledge_graph_node("act_r", "ACT-R", node_type = "concept", memory_type = "semantic"),
    edges = .empty_knowledge_graph_edges(),
    metadata = list(graph_mode = "curated")
  )
  knowledge <- KnowledgeSpec$new(
    items = list(list(
      id = "ki_actr_001",
      type = "concept",
      raw_statement = "ACT-R is a cognitive architecture.",
      normalized_statement = "ACT-R is a cognitive architecture.",
      review = list(status = "approved")
    )),
    graph = graph
  )

  save_memory_spec_yaml(memory, memory_path)
  save_knowledge_spec_yaml(knowledge, knowledge_path)
  save_knowledge_graph_spec_yaml(graph, graph_path)

  loaded_memory <- load_memory_spec_yaml(memory_path)
  loaded_knowledge <- load_knowledge_spec_yaml(knowledge_path)
  loaded_graph <- load_knowledge_graph_spec_yaml(graph_path)

  expect_s3_class(loaded_memory, "MemorySpec")
  expect_s3_class(loaded_knowledge, "KnowledgeSpec")
  expect_s3_class(loaded_graph, "agentr_knowledge_graph_spec")
  expect_equal(loaded_memory$get_field("state_task")$schema$required, "task_id")
  expect_equal(loaded_knowledge$graph$nodes$id[[1]], "act_r")
  expect_equal(loaded_graph$nodes$id[[1]], "act_r")
})
