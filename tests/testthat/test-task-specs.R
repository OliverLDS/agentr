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

  paths <- task_spec_paths(task_dir)
  save_workflow_spec_yaml(workflow, paths$workflow)
  save_memory_spec_yaml(memory, paths$memory)
  save_knowledge_spec_yaml(knowledge, paths$knowledge)

  manifest <- discover_task_specs(task_dir)
  expect_equal(manifest$type, c("workflow", "memory", "knowledge"))
  expect_true(all(manifest$exists))

  loaded <- load_task_specs(task_dir)
  expect_s3_class(loaded, "agentr_task_specs")
  expect_s3_class(loaded$workflow, "agentr_workflow_spec")
  expect_s3_class(loaded$memory, "MemorySpec")
  expect_s3_class(loaded$knowledge, "KnowledgeSpec")

  result <- validate_task_specs(task_dir, require = c("workflow", "memory"), stop_on_error = TRUE)
  expect_true(all(result$valid))
  expect_equal(result$message, rep("valid", 3L))
})

test_that("task-local validation reports missing optional and required specs", {
  task_dir <- file.path(tempdir(), paste0("agentr_sparse_task_", Sys.getpid()))
  dir.create(file.path(task_dir, "docs"), recursive = TRUE, showWarnings = FALSE)

  result <- validate_task_specs(task_dir)
  expect_false(any(result$exists))
  expect_false(any(result$valid))
  expect_equal(result$message, rep("missing optional spec", 3L))

  required <- validate_task_specs(task_dir, require = "workflow")
  expect_equal(required$message[required$type == "workflow"], "missing required spec")
  expect_error(
    validate_task_specs(task_dir, require = "workflow", stop_on_error = TRUE),
    "workflow: missing required spec"
  )
})

test_that("render_task_preview includes optional memory, knowledge, and graph specs", {
  task_dir <- file.path(tempdir(), paste0("agentr_preview_task_", Sys.getpid()))
  docs_dir <- file.path(task_dir, "docs")
  dir.create(docs_dir, recursive = TRUE, showWarnings = FALSE)

  workflow <- new_workflow_spec(
    nodes = workflow_node(
      id = "node_read",
      label = "Read task input",
      human_required = FALSE,
      owner = "script",
      automation_status = "rule_assisted",
      knowledge_refs = c("ki_review_rule_001")
    ),
    edges = .empty_workflow_edges(),
    task = "Preview fixture task"
  )
  memory <- MemorySpec$new(fields = list(
    memory_field(
      id = "run_log",
      label = "Run log",
      memory_type = "episodic",
      description = "Past preview render runs.",
      schema = list(type = "object", required = c("timestamp")),
      persistence = "jsonl_trace"
    )
  ))
  graph <- list(
    nodes = list(
      list(id = "review_rule", label = "Review rule", node_type = "concept", memory_type = "semantic"),
      list(id = "human_review", label = "Human review", node_type = "criterion", memory_type = "semantic")
    ),
    edges = list(list(from = "review_rule", to = "human_review", relation = "requires", relation_type = "requires")),
    metadata = list(graph_mode = "curated")
  )
  knowledge <- KnowledgeSpec$new(
    items = list(list(
      id = "ki_review_rule_001",
      type = "rule",
      raw_statement = "Human review is required before publishing.",
      normalized_statement = "Human review is required before publishing.",
      review = list(status = "approved")
    )),
    graph = graph
  )

  paths <- task_spec_paths(task_dir)
  save_workflow_spec_yaml(workflow, paths$workflow)
  save_memory_spec_yaml(memory, paths$memory)
  save_knowledge_spec_yaml(knowledge, paths$knowledge)

  out <- render_task_preview(task_dir, graph_layout = "process", edge_style = "orthogonal")
  expect_true(file.exists(out))

  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("Run log", html, fixed = TRUE))
  expect_true(grepl("ki_review_rule_001", html, fixed = TRUE))
  expect_true(grepl("Review rule", html, fixed = TRUE))
  expect_true(grepl("\"fields\":[{\"id\":\"run_log\"", html, fixed = TRUE))
  expect_true(grepl("\"items\":[{\"id\":\"ki_review_rule_001\"", html, fixed = TRUE))
  expect_true(grepl("\"nodes\":[{\"id\":\"review_rule\"", html, fixed = TRUE))
})

test_that("render_task_preview embeds subworkflow_ref child specs for standalone review", {
  task_dir <- file.path(tempdir(), paste0("agentr_subworkflow_preview_", Sys.getpid()))
  child_dir <- file.path(task_dir, "nodes", "node_child", "docs")
  dir.create(file.path(task_dir, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(child_dir, recursive = TRUE, showWarnings = FALSE)

  child <- new_workflow_spec(
    nodes = workflow_node("child_step", "Child workflow step", human_required = FALSE),
    edges = .empty_workflow_edges(),
    task = "Child task"
  )
  parent <- new_workflow_spec(
    nodes = workflow_node(
      "node_child",
      "Parent node with child workflow",
      human_required = FALSE,
      subworkflow_ref = "nodes/node_child/docs/workflow_spec.yaml"
    ),
    edges = .empty_workflow_edges(),
    task = "Parent task"
  )

  save_workflow_spec_yaml(parent, task_spec_paths(task_dir)$workflow)
  save_workflow_spec_yaml(child, file.path(child_dir, "workflow_spec.yaml"))

  out <- render_task_preview(task_dir)
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")

  expect_true(grepl('"subworkflow_ref":"nodes/node_child/docs/workflow_spec.yaml"', html, fixed = TRUE))
  expect_true(grepl('"nested_workflow":{"nodes":[{"id":"child_step"', html, fixed = TRUE))
  expect_true(grepl("Child workflow step", html, fixed = TRUE))
  expect_true(grepl("openSubworkflowModal", html, fixed = TRUE))
})

test_that("render_task_previews renders all discovered task-local workflows", {
  root <- file.path(tempdir(), paste0("agentr_preview_root_", Sys.getpid()))
  task_a <- file.path(root, "tasks", "task_a")
  task_b <- file.path(root, "tasks", "task_b")
  dir.create(file.path(task_a, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(task_b, "docs"), recursive = TRUE, showWarnings = FALSE)

  workflow_a <- new_workflow_spec(
    nodes = workflow_node("node_a", "Node A", human_required = FALSE),
    edges = .empty_workflow_edges(),
    task = "Task A"
  )
  workflow_b <- new_workflow_spec(
    nodes = workflow_node("node_b", "Node B", human_required = FALSE),
    edges = .empty_workflow_edges(),
    task = "Task B"
  )
  save_workflow_spec_yaml(workflow_a, task_spec_paths(task_a)$workflow)
  save_workflow_spec_yaml(workflow_b, task_spec_paths(task_b)$workflow)

  rendered <- render_task_previews(root)

  expect_equal(nrow(rendered), 2L)
  expect_true(all(file.exists(rendered$review_path)))
  expect_true(any(grepl("task_a", rendered$task_dir, fixed = TRUE)))
  expect_true(any(grepl("task_b", rendered$task_dir, fixed = TRUE)))
})
