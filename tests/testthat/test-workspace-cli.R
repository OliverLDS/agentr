test_that("agentr workspace initializes generic lifecycle directories", {
  workspace <- tempfile("agentr_workspace_")
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)

  paths <- init_agentr_workspace(workspace, comment = "Generic review workspace")

  expect_true(dir.exists(paths$specs))
  expect_true(dir.exists(paths$proposal_states))
  expect_true(dir.exists(paths$initial_prompts))
  expect_true(dir.exists(paths$revision_prompts))
  expect_true(dir.exists(paths$reviews))
  expect_true(file.exists(file.path(paths$root, "README.md")))
  expect_true(grepl("Generic review workspace", paste(readLines(file.path(paths$root, "README.md")), collapse = "\n"), fixed = TRUE))
})

test_that("workspace prompt builders write manual LLM prompt files", {
  workspace <- tempfile("agentr_workspace_")
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)

  workflow_prompt <- build_initial_spec_prompt(
    workspace,
    target = "workflow",
    comment = "Design a workflow for reviewing a paper.",
    format = "markdown"
  )
  memory_prompt <- build_initial_spec_prompt(
    workspace,
    target = "memory",
    comment = "Design memory for a paper-review assistant.",
    format = "markdown"
  )

  expect_true(file.exists(workflow_prompt))
  expect_true(file.exists(memory_prompt))
  expect_true(grepl("Memory Schema Prompt", paste(readLines(memory_prompt), collapse = "\n"), fixed = TRUE))
})

test_that("workspace memory lifecycle applies, lists, and approves proposals", {
  workspace <- tempfile("agentr_workspace_")
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)
  paths <- init_agentr_workspace(workspace)

  spec <- .test_complete_agent_spec()
  save_agent_spec(spec, paths$agent_spec)
  init_agentr_proposal_states(workspace)

  message <- jsonlite::toJSON(list(actions = list(list(
    method = "propose_memory_schema",
    args = list(
      proposal_id = "memory_proposal_test",
      memory_spec = list(
        fields = list(list(
          id = "current_review_target",
          label = "Current review target",
          memory_type = "context",
          description = "Current artifact under review.",
          persistence = "session"
        )),
        metadata = list(source = "test")
      ),
      notes = "Test memory schema"
    )
  ))), auto_unbox = TRUE, null = "null")

  apply_initial_spec_message(workspace, target = "memory", message = message)
  listed <- list_workspace_proposals(workspace, type = "memory")

  expect_equal(listed$id[[1]], "memory_proposal_test")
  expect_equal(listed$status[[1]], "pending")

  approve_workspace_proposal(workspace, type = "memory", proposal_id = "memory_proposal_test")
  memory_state <- readRDS(paths$memory_state)
  loaded_spec <- load_agent_spec(paths$agent_spec)

  expect_equal(memory_state$approved_memory_spec$get_field("current_review_target")$memory_type, "context")
  expect_equal(loaded_spec$memory_spec$get_field("current_review_target")$label, "Current review target")
})

test_that("workspace workflow revisions store proposals without mutating approved workflow", {
  workspace <- tempfile("agentr_workspace_")
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)
  paths <- init_agentr_workspace(workspace)

  spec <- .test_complete_agent_spec()
  save_agent_spec(spec, paths$agent_spec)
  init_agentr_proposal_states(workspace)

  message <- jsonlite::toJSON(list(actions = list(list(
    method = "decompose_task",
    args = list(
      nodes = list(
        list(id = "node_a", label = "Read source document"),
        list(id = "node_b", label = "Extract structured findings")
      ),
      edges = list(list(from = "node_a", to = "node_b"))
    )
  ))), auto_unbox = TRUE, null = "null")

  preview <- apply_revision_message(workspace, target = "workflow", message = message)
  workflow_state <- readRDS(paths$workflow_state)

  expect_equal(length(workflow_state$list_proposals()$id), 1L)
  expect_equal(nrow(workflow_state$approved_workflow$nodes), nrow(spec$workflow$nodes))
  expect_equal(nrow(preview$workflow_after$nodes), 2L)
})

test_that("workspace initial workflow application stores a pending proposal when omitted", {
  workspace <- tempfile("agentr_workspace_")
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)
  paths <- init_agentr_workspace(workspace)

  message <- jsonlite::toJSON(list(actions = list(list(
    method = "decompose_task",
    args = list(nodes = list(list(id = "node_1", label = "Draft workflow")))
  ))), auto_unbox = TRUE, null = "null")

  apply_initial_spec_message(workspace, target = "workflow", message = message)
  workflow_state <- readRDS(paths$workflow_state)
  proposals <- workflow_state$list_proposals()

  expect_equal(workflow_state$approved_workflow$task, "Workspace design imported from initial LLM response")
  expect_equal(nrow(workflow_state$approved_workflow$nodes), 0L)
  expect_equal(nrow(proposals), 1L)
  expect_equal(proposals$status[[1]], "pending")
  expect_equal(proposals$node_count[[1]], 1L)
})

test_that("workspace review export supports workflow-only proposal state", {
  workspace <- tempfile("agentr_workspace_")
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)

  message <- jsonlite::toJSON(list(actions = list(list(
    method = "decompose_task",
    args = list(nodes = list(list(id = "node_1", label = "Draft workflow")))
  ))), auto_unbox = TRUE, null = "null")

  apply_initial_spec_message(workspace, target = "workflow", message = message)
  review_path <- export_workspace_design_review(workspace, graph_layout = "process", edge_style = "orthogonal")
  html <- paste(readLines(review_path, warn = FALSE), collapse = "\n")

  expect_true(file.exists(review_path))
  expect_true(grepl("Draft workflow", html, fixed = TRUE))
  expect_true(grepl("proposal_1", html, fixed = TRUE))
  expect_true(grepl('"graph_layout":"process"', html, fixed = TRUE))
  expect_true(grepl('"edge_style":"orthogonal"', html, fixed = TRUE))
})

test_that("workspace review and handoff exporters write artifacts", {
  workspace <- tempfile("agentr_workspace_")
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)
  paths <- init_agentr_workspace(workspace)

  spec <- .test_complete_agent_spec()
  save_agent_spec(spec, paths$agent_spec)
  init_agentr_proposal_states(workspace)

  review_path <- export_workspace_design_review(workspace)
  handoff_path <- build_workspace_implementation_prompt(workspace, format = "markdown")

  expect_true(file.exists(review_path))
  expect_true(file.exists(handoff_path))
  expect_true(grepl("implementation", paste(readLines(handoff_path), collapse = "\n"), ignore.case = TRUE))
})

test_that("CLI wrapper exposes help text and supported commands", {
  cli_path <- system.file("cli", "agentr-cli.R", package = "agentr")
  if (!nzchar(cli_path)) {
    cli_path <- normalizePath(file.path("..", "..", "inst", "cli", "agentr-cli.R"), mustWork = TRUE)
  }
  cli <- paste(readLines(cli_path, warn = FALSE), collapse = "\n")

  expect_true(grepl("print_help", cli, fixed = TRUE))
  expect_true(grepl("build-initial-prompt", cli, fixed = TRUE))
  expect_true(grepl("apply-revision-message", cli, fixed = TRUE))
  expect_true(grepl("approve-proposal", cli, fixed = TRUE))
  expect_true(grepl("export-review", cli, fixed = TRUE))
  expect_true(grepl("--workspace PATH", cli, fixed = TRUE))
  expect_true(grepl("--message RESPONSE_JSON", cli, fixed = TRUE))
  expect_false(grepl("pos = 1", cli, fixed = TRUE))
  expect_true(grepl("--graph-layout", cli, fixed = TRUE))
  expect_true(grepl("--edge-style", cli, fixed = TRUE))
})
