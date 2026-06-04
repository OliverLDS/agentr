test_that("task-local spec helpers discover, load, and validate YAML specs", {
  task_dir <- file.path(tempdir(), paste0("agentr_task_", Sys.getpid()))
  docs_dir <- file.path(task_dir, "docs")
  dir.create(docs_dir, recursive = TRUE, showWarnings = FALSE)

  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node(
        id = "node_read",
        label = "Read source file",
        human_required = FALSE,
        owner = "script",
        automation_status = "rule_assisted"
      ),
      workflow_node(
        id = "node_write",
        label = "Write JSON output",
        human_required = FALSE,
        owner = "script",
        automation_status = "rule_assisted"
      )
    ),
    edges = workflow_edge("node_read", "node_write"),
    task = "Fixture task"
  )
  memory <- MemorySpec$new(fields = list(
    memory_field(
      id = "current_task",
      label = "Current task",
      memory_type = "context",
      description = "Current task state.",
      schema = list(type = "object", required = c("task_id")),
      persistence = "session"
    )
  ))
  graph <- new_knowledge_graph_spec(
    nodes = knowledge_graph_node("act_r", "ACT-R", node_type = "concept", memory_type = "semantic"),
    edges = knowledge_graph_edge(character(), character()),
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

  paths <- task_spec_paths(task_dir)
  save_workflow_spec_yaml(workflow, paths$workflow)
  save_memory_spec_yaml(memory, paths$memory)
  save_knowledge_spec_yaml(knowledge, paths$knowledge)
  save_knowledge_graph_spec_yaml(graph, paths$knowledge_graph)

  manifest <- discover_task_specs(task_dir)
  expect_equal(manifest$type, c("workflow", "memory", "knowledge", "knowledge_graph"))
  expect_true(all(manifest$exists))

  loaded <- load_task_specs(task_dir)
  expect_s3_class(loaded, "agentr_task_specs")
  expect_s3_class(loaded$workflow, "agentr_workflow_spec")
  expect_s3_class(loaded$memory, "MemorySpec")
  expect_s3_class(loaded$knowledge, "KnowledgeSpec")
  expect_s3_class(loaded$knowledge_graph, "agentr_knowledge_graph_spec")

  result <- validate_task_specs(task_dir, require = c("workflow", "memory"), stop_on_error = TRUE)
  expect_true(all(result$valid))
  expect_equal(result$message, rep("valid", 4L))
})

test_that("task-local validation reports missing optional and required specs", {
  task_dir <- file.path(tempdir(), paste0("agentr_sparse_task_", Sys.getpid()))
  dir.create(file.path(task_dir, "docs"), recursive = TRUE, showWarnings = FALSE)

  result <- validate_task_specs(task_dir)
  expect_false(any(result$exists))
  expect_false(any(result$valid))
  expect_equal(result$message, rep("missing optional spec", 4L))

  required <- validate_task_specs(task_dir, require = "workflow")
  expect_equal(required$message[required$type == "workflow"], "missing required spec")
  expect_error(
    validate_task_specs(task_dir, require = "workflow", stop_on_error = TRUE),
    "workflow: missing required spec"
  )
})
