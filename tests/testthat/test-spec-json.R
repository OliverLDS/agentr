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
    edges = workflow_edge(
      "node_1",
      "node_2",
      relation = "exclusive_branch",
      condition = "source_count == 1",
      branch_group = "source_count_route",
      mutually_exclusive = TRUE
    ),
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
  expect_equal(loaded$edges$condition[[1]], "source_count == 1")
  expect_equal(loaded$edges$branch_group[[1]], "source_count_route")
  expect_true(loaded$edges$mutually_exclusive[[1]])
  saved_json <- paste(readLines(path, warn = FALSE), collapse = "")
  expect_true(grepl('"knowledge_refs":\\s*\\["ki_1"\\]', saved_json))
  expect_true(grepl('"required":\\s*\\["source"\\]', saved_json))
  expect_true(grepl('"condition":\\s*"source_count == 1"', saved_json))
  expect_true(grepl('"branch_group":\\s*"source_count_route"', saved_json))
  expect_true(grepl('"mutually_exclusive":\\s*true', saved_json))

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

test_that("workflow specs preserve data node metadata through JSON", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)

  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node(
        id = "knowledge_rules",
        label = "Article style knowledge",
        node_kind = "knowledge",
        human_required = FALSE,
        source_path = "docs/knowledge_spec.yaml",
        retrieval_mode = "yaml_lookup",
        persistence = "static",
        linked_spec_ids = c("knowledge_spec.yaml", "ki_style_rules")
      ),
      workflow_node(
        id = "build_prompt",
        label = "Build prompt",
        human_required = FALSE
      )
    ),
    edges = workflow_edge("knowledge_rules", "build_prompt", relation = "prompts_with"),
    task = "Data node metadata"
  )

  save_workflow_spec(workflow, path)
  loaded <- load_workflow_spec(path)

  expect_equal(loaded$nodes$node_kind[[1]], "knowledge")
  expect_equal(loaded$nodes$source_path[[1]], "docs/knowledge_spec.yaml")
  expect_equal(loaded$nodes$retrieval_mode[[1]], "yaml_lookup")
  expect_equal(loaded$nodes$persistence[[1]], "static")
  expect_equal(loaded$nodes$linked_spec_ids[[1]], c("knowledge_spec.yaml", "ki_style_rules"))
  expect_equal(loaded$edges$relation[[1]], "prompts_with")
  saved_json <- paste(readLines(path, warn = FALSE), collapse = "")
  expect_true(grepl('"linked_spec_ids":\\s*\\["knowledge_spec.yaml"', saved_json))
})

test_that("workflow specs reject unsupported node kinds", {
  workflow <- new_workflow_spec(
    nodes = workflow_node("knowledge_rules", "Knowledge rules", node_kind = "knowledge", human_required = FALSE),
    edges = .empty_workflow_edges()
  )

  expect_equal(workflow$nodes$node_kind[[1]], "knowledge")

  invalid <- workflow
  invalid$nodes$node_kind[[1]] <- "runtime_executor"
  expect_error(validate_workflow_spec(invalid), "node_kind")
})

test_that("workflow data nodes default away from human gates", {
  node <- workflow_node("memory_state", "Memory state", node_kind = "memory")

  expect_false(node$human_required[[1]])
})

test_that("workflow status nodes validate as process-visible markers", {
  node <- workflow_node("failure_status", "Failure detected", node_kind = "status")
  workflow <- new_workflow_spec(
    nodes = node,
    edges = .empty_workflow_edges(),
    task = "Status marker"
  )

  expect_equal(workflow$nodes$node_kind[[1]], "status")
  expect_false(workflow$nodes$human_required[[1]])
  expect_no_error(validate_workflow_spec(workflow))
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

  graph <- list(
    nodes = list(
      list(id = "act_r", label = "ACT-R", node_type = "concept", memory_type = "semantic"),
      list(id = "cognitive_architecture", label = "cognitive architecture", node_type = "concept", memory_type = "semantic")
    ),
    edges = list(
      list(
        from = "act_r",
        to = "cognitive_architecture",
        relation = "is_a",
        relation_type = "is_a",
        memory_type = "semantic"
      )
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
  expect_equal(loaded$list_items()[[1]]$id, "ki_actr_001")
  expect_equal(loaded$graph$edges[[1]]$relation, "is_a")
  expect_equal(loaded$graph$metadata$graph_mode, "curated")
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
    edges = workflow_edge(
      "node_1",
      "node_1",
      relation = "exclusive_branch",
      condition = "retry_needed",
      branch_group = "retry_route",
      mutually_exclusive = TRUE
    ),
    task = "YAML round-trip"
  )

  save_workflow_spec(workflow, path)
  loaded <- load_workflow_spec(path)

  expect_s3_class(loaded, "agentr_workflow_spec")
  expect_equal(loaded$nodes$knowledge_refs[[1]], "ki_1")
  expect_equal(loaded$nodes$input_schema[[1]]$required, "source")
  expect_equal(loaded$edges$condition[[1]], "retry_needed")
  expect_equal(loaded$edges$branch_group[[1]], "retry_route")
  expect_true(loaded$edges$mutually_exclusive[[1]])

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

test_that("memory and knowledge specs round-trip through YAML with graph representations", {
  memory_path <- tempfile(fileext = ".yaml")
  knowledge_path <- tempfile(fileext = ".yaml")
  on.exit(unlink(c(memory_path, knowledge_path)), add = TRUE)

  memory <- MemorySpec$new(fields = list(
    memory_field(
      id = "state_task",
      label = "Task state",
      memory_type = "context",
      schema = list(type = "object", required = c("task_id"))
    )
  ))
  graph <- list(
    nodes = list(list(id = "act_r", label = "ACT-R", node_type = "concept", memory_type = "semantic")),
    edges = list(),
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

  loaded_memory <- load_memory_spec_yaml(memory_path)
  loaded_knowledge <- load_knowledge_spec_yaml(knowledge_path)

  expect_s3_class(loaded_memory, "MemorySpec")
  expect_s3_class(loaded_knowledge, "KnowledgeSpec")
  expect_equal(loaded_memory$get_field("state_task")$schema$required, "task_id")
  expect_equal(loaded_knowledge$graph$nodes[[1]]$id, "act_r")
})
