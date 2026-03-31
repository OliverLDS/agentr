test_that("CognitiveState stores structured updates", {
  state <- CognitiveState$new()
  state$set_belief("package_scope", "core only", confidence = 0.9)
  state$set_goal("release", "Ship 0.1.3")
  state$set_context(task = "refactor")

  snapshot <- state$as_list()

  expect_true(identical(snapshot$beliefs$package_scope, "core only"))
  expect_true(identical(snapshot$goals$release$status, "proposed"))
  expect_true(identical(snapshot$task_context$task, "refactor"))
  expect_true(isTRUE(all.equal(unname(snapshot$confidence["package_scope"]), 0.9)))
})

test_that("AffectiveState updates with inertia and stays bounded", {
  affect <- AffectiveState$new()
  affect$update_primary(c(joy = 0.9, trust = 0.8))

  state <- affect$as_list()

  expect_true(state$primary["joy"] > 0.1)
  expect_true(state$primary["joy"] < 0.9)
  expect_true(all(state$primary >= 0))
  expect_true(all(state$primary <= 1))
})

test_that("Scaffolder supports discussion, review, and graph editing", {
  agent <- AgentCore$new()
  scaffolder <- Scaffolder$new(agent = agent)

  scaffolder$evaluate_task(
    "Design a workflow",
    summary = "Design a reviewable workflow",
    blockers = c("Need approval path")
  )
  scaffolder$discuss_task("We may need a parallel review branch.", source = "human")
  scaffolder$decompose_task(suggestions = list(
    nodes = list(
      list(id = "node_1", label = "Clarify"),
      list(id = "node_2", label = "Plan"),
      list(id = "node_3", label = "Translate", depends_on = c("node_1", "node_2"))
    )
  ))
  scaffolder$review_workflow(status = "needs_revision", notes = "Missing approval review")
  scaffolder$review_node("node_1", status = "approved", notes = "Clear", complete = TRUE)
  scaffolder$edit_workflow(
    insert = list(list(
      node = list(label = "Approval review", confidence = 0.7),
      between = list("node_2", "node_3")
    )),
    rule_specs = list(node_2 = "Require approval before branching"),
    confidence = list(node_3 = 0.4)
  )

  spec <- scaffolder$workflow_spec()

  expect_s3_class(spec, "agentr_workflow_spec")
  expect_true(identical(nrow(spec$nodes), 4L))
  expect_true(spec$nodes$complete[spec$nodes$id == "node_1"])
  expect_true(identical(
    spec$nodes$rule_spec[spec$nodes$id == "node_2"],
    "Require approval before branching"
  ))
  expect_true(isTRUE(all.equal(
    spec$nodes$confidence[spec$nodes$id == "node_3"],
    0.4
  )))
  expect_true(identical(
    spec$nodes$review_status[spec$nodes$id == "node_1"],
    "approved"
  ))
  expect_true(identical(
    spec$metadata$workflow_review$status,
    "needs_revision"
  ))
  expect_true(identical(length(spec$metadata$discussion_rounds), 1L))
  expect_true(identical(nrow(spec$edges), 3L))
  expect_true(identical(nrow(scaffolder$low_confidence_nodes()), 2L))
})

test_that("save_agent and load_agent round-trip core objects", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  agent <- AgentCore$new(name = "persisted")
  save_agent(agent, path)
  loaded <- load_agent(path)

  expect_true(inherits(loaded, "AgentCore"))
  expect_true(identical(loaded$name, "persisted"))
})

test_that("save_workflow_spec and load_workflow_spec round-trip workflow specs", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  spec <- new_workflow_spec(
    nodes = rbind(
      workflow_node("node_1", "Clarify"),
      workflow_node("node_2", "Translate")
    ),
    edges = workflow_edge("node_1", "node_2"),
    task = "Round-trip workflow"
  )

  save_workflow_spec(spec, path)
  loaded <- load_workflow_spec(path)

  expect_s3_class(loaded, "agentr_workflow_spec")
  expect_true(identical(loaded$task, "Round-trip workflow"))
  expect_true(identical(nrow(loaded$nodes), 2L))
})

test_that("build_scaffolder_prompt supports json and markdown outputs", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Build a DAG for a package release")
  scaffolder$decompose_task(candidates = c("Clarify", "Ask rules"))

  prompt_json <- build_scaffolder_prompt(scaffolder, format = "json")
  prompt_markdown <- build_scaffolder_prompt(scaffolder, format = "markdown")

  expect_true(grepl("\"task\": \"Build a DAG for a package release\"", prompt_json, fixed = TRUE))
  expect_true(grepl("\"available_methods\"", prompt_json, fixed = TRUE))
  expect_true(grepl("\"response_requirements\"", prompt_json, fixed = TRUE))
  expect_true(grepl("\"discuss_task\"", prompt_json, fixed = TRUE))
  expect_true(grepl("# Scaffolding Reasoning Prompt", prompt_markdown, fixed = TRUE))
  expect_true(grepl("## Available Scaffolder Methods", prompt_markdown, fixed = TRUE))
  expect_true(grepl("edit_workflow", prompt_markdown, fixed = TRUE))
  expect_true(grepl("downloadable `.json` file or attachment link", prompt_markdown, fixed = TRUE))
  expect_true(grepl("The file contents must be machine-readable JSON only", prompt_markdown, fixed = TRUE))
  expect_true(grepl("Use discuss_task to preserve free-form human or model reasoning before committing graph edits", prompt_markdown, fixed = TRUE))
})

test_that("build_implementation_prompt supports scaffolder and workflow inputs", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Implement an economic analysis workflow")
  scaffolder$decompose_task(suggestions = list(
    nodes = list(
      list(id = "node_1", label = "Refresh data", implementation_hint = "Download latest macro data"),
      list(id = "node_2", label = "Run analysis", depends_on = "node_1", rule_spec = "Summarize trend changes"),
      list(id = "node_3", label = "Write report", depends_on = "node_2", human_required = TRUE)
    )
  ))

  prompt_json <- build_implementation_prompt(
    scaffolder,
    language = "R",
    runtime = "R package",
    constraints = c("Prefer testthat", "Keep code modular")
  )
  prompt_markdown <- build_implementation_prompt(
    scaffolder$workflow_spec(),
    language = "Python",
    format = "markdown",
    target_agent = "codex"
  )

  expect_true(grepl("\"target_language\": \"R\"", prompt_json, fixed = TRUE))
  expect_true(grepl("\"implementation_plan\"", prompt_json, fixed = TRUE))
  expect_true(grepl("\"Refresh data\"", prompt_json, fixed = TRUE))
  expect_true(grepl("# Implementation Planning Prompt", prompt_markdown, fixed = TRUE))
  expect_true(grepl("Target coding agent: `codex`.", prompt_markdown, fixed = TRUE))
  expect_true(grepl("## Workflow Input", prompt_markdown, fixed = TRUE))
  expect_true(grepl("machine-readable JSON only", prompt_markdown, fixed = TRUE))
})

test_that("build_workflow_extraction_prompt supports json and markdown outputs", {
  code_context <- c(
    "fetch_data <- function() read.csv('latest.csv')",
    "analyze_data <- function(df) summary(df)",
    "write_report <- function(stats) cat('report')"
  )

  prompt_json <- build_workflow_extraction_prompt(
    code_context = code_context,
    task = "Infer a reporting workflow from ad hoc code",
    language = "R"
  )
  prompt_markdown <- build_workflow_extraction_prompt(
    code_context = code_context,
    task = "Infer a reporting workflow from ad hoc code",
    language = "R",
    format = "markdown"
  )

  expect_true(grepl("\"workflow_extractor\"", prompt_json, fixed = TRUE))
  expect_true(grepl("\"task\": \"Infer a reporting workflow from ad hoc code\"", prompt_json, fixed = TRUE))
  expect_true(grepl("\"nodes\"", prompt_json, fixed = TRUE))
  expect_true(grepl("# Workflow Extraction Prompt", prompt_markdown, fixed = TRUE))
  expect_true(grepl("Return a top-level workflow specification object, not scaffolder actions", prompt_markdown, fixed = TRUE))
  expect_true(grepl("downloadable `.json` file or attachment link", prompt_markdown, fixed = TRUE))
})

test_that("parse and validate scaffolder message accept valid json", {
  text <- jsonlite::toJSON(
    list(
      actions = list(
        list(
          method = "decompose_task",
          args = list(candidates = list("Clarify", "Draft"))
        ),
        list(
          method = "ask_human_changes",
          args = list()
        )
      ),
      notes = "Use the human for gaps."
    ),
    auto_unbox = TRUE
  )

  parsed <- parse_scaffolder_message(text)

  expect_true(is.list(parsed))
  expect_true(identical(parsed$actions[[1]]$method, "decompose_task"))
  expect_true(identical(parsed$actions[[2]]$method, "ask_human_changes"))
})

test_that("parse_scaffolder_message accepts a downloaded json file path", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)

  writeLines(
    jsonlite::toJSON(
      list(
        actions = list(
          list(method = "ask_human_changes", args = list())
        )
      ),
      auto_unbox = TRUE
    ),
    path
  )

  parsed <- parse_scaffolder_message(path)

  expect_true(is.list(parsed))
  expect_true(identical(parsed$actions[[1]]$method, "ask_human_changes"))
})

test_that("apply_scaffolder_message dispatches actions to scaffolder methods", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  message <- list(
    actions = list(
      list(
        method = "evaluate_task",
        args = list(task = "Draft a workflow", summary = "Initial task assessment")
      ),
      list(
        method = "discuss_task",
        args = list(feedback = "Human wants a review checkpoint.", source = "human")
      ),
      list(
        method = "decompose_task",
        args = list(suggestions = list(
          nodes = list(
            list(id = "node_1", label = "Clarify"),
            list(id = "node_2", label = "Translate")
          ),
          edges = list(list(from = "node_1", to = "node_2", relation = "depends_on"))
        ))
      ),
      list(
        method = "edit_workflow",
        args = list(
          confidence = list(node_1 = 0.9),
          rule_specs = list(node_2 = "Require a final review"),
          add_edges = list(list(from = "node_1", to = "node_2", relation = "depends_on"))
        )
      )
    )
  )

  out <- apply_scaffolder_message(scaffolder, message)

  expect_true(is.list(out))
  expect_true(identical(
    names(out),
    c("applied_actions", "workflow_after", "human_prompts", "errors")
  ))
  expect_true(identical(length(out$applied_actions), 4L))
  expect_true(identical(scaffolder$task, "Draft a workflow"))
  expect_true(identical(nrow(scaffolder$workflow$nodes), 2L))
  expect_true(identical(length(scaffolder$workflow$metadata$discussion_rounds), 1L))
  expect_true(isTRUE(all.equal(
    scaffolder$workflow$nodes$confidence[scaffolder$workflow$nodes$id == "node_1"],
    0.9
  )))
  expect_true(identical(
    scaffolder$workflow$nodes$rule_spec[scaffolder$workflow$nodes$id == "node_2"],
    "Require a final review"
  ))
  expect_true(identical(length(out$errors), 0L))
})

test_that("apply_scaffolder_message accepts a downloaded json file path", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)

  writeLines(
    jsonlite::toJSON(
      list(
        actions = list(
          list(method = "evaluate_task", args = list(task = "Draft from file")),
          list(method = "decompose_task", args = list(candidates = list("Clarify", "Translate")))
        )
      ),
      auto_unbox = TRUE
    ),
    path
  )

  out <- apply_scaffolder_message(scaffolder, path)

  expect_true(identical(scaffolder$task, "Draft from file"))
  expect_true(identical(nrow(out$workflow_after$nodes), 2L))
})

test_that("workflow proposals can be previewed, discussed, and approved", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Design an autonomous workflow")

  message <- list(
    actions = list(
      list(
        method = "decompose_task",
        args = list(suggestions = list(
          nodes = list(
            list(id = "node_1", label = "Refresh data"),
            list(id = "node_2", label = "Write report", depends_on = "node_1")
          )
        ))
      )
    ),
    notes = "Initial model proposal."
  )

  preview <- preview_scaffolder_message(scaffolder, message)
  proposals <- scaffolder$list_workflow_proposals()

  expect_true(identical(nrow(scaffolder$workflow$nodes), 0L))
  expect_true(identical(nrow(preview$workflow_after$nodes), 2L))
  expect_true(identical(nrow(proposals), 1L))
  expect_true(identical(proposals$status[[1]], "pending"))

  proposal <- scaffolder$get_workflow_proposal(preview$proposal_id)
  expect_true(identical(proposal$notes, "Initial model proposal."))

  scaffolder$discuss_workflow_proposal(
    preview$proposal_id,
    "Need a dedicated review checkpoint before publication."
  )
  proposal <- scaffolder$get_workflow_proposal(preview$proposal_id)
  expect_true(identical(length(proposal$discussion_rounds), 1L))
  expect_true(identical(proposal$status, "under_discussion"))

  scaffolder$approve_workflow_proposal(preview$proposal_id)
  proposals <- scaffolder$list_workflow_proposals()
  expect_true(identical(nrow(scaffolder$workflow$nodes), 2L))
  expect_true(identical(proposals$status[[1]], "approved"))
})

test_that("approved proposals cannot be reopened by discussion", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Freeze approved workflows")

  proposal <- scaffolder$propose_workflow(
    new_workflow_spec(
      nodes = rbind(
        workflow_node("node_1", "Clarify"),
        workflow_node("node_2", "Approve")
      ),
      edges = workflow_edge("node_1", "node_2"),
      task = "Freeze approved workflows"
    )
  )
  scaffolder$approve_workflow_proposal(proposal$id)

  expect_error(
    scaffolder$discuss_workflow_proposal(proposal$id, "Please revise this."),
    "Cannot discuss an approved workflow proposal directly"
  )
})

test_that("approving a newer proposal supersedes older active proposals", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Supersede stale proposals")

  proposal_1 <- scaffolder$propose_workflow(
    new_workflow_spec(
      nodes = workflow_node("node_1", "Initial draft"),
      edges = .empty_workflow_edges(),
      task = "Supersede stale proposals"
    ),
    notes = "Older proposal"
  )

  proposal_2 <- scaffolder$propose_workflow(
    new_workflow_spec(
      nodes = rbind(
        workflow_node("node_1", "Initial draft"),
        workflow_node("node_2", "Human review")
      ),
      edges = workflow_edge("node_1", "node_2"),
      task = "Supersede stale proposals"
    ),
    notes = "Newer proposal"
  )

  scaffolder$discuss_workflow_proposal(proposal_1$id, "This needs a review step.")
  scaffolder$approve_workflow_proposal(proposal_2$id)

  proposals <- scaffolder$list_workflow_proposals()
  proposal_1_after <- scaffolder$get_workflow_proposal(proposal_1$id)
  proposal_2_after <- scaffolder$get_workflow_proposal(proposal_2$id)

  expect_true(identical(proposal_1_after$status, "superseded"))
  expect_true(identical(proposal_1_after$superseded_by, proposal_2$id))
  expect_true(identical(proposal_2_after$status, "approved"))
  expect_true(identical(scaffolder$workflow$nodes$label[[2]], "Human review"))
  expect_true(any(proposals$status == "superseded"))
  expect_true(any(proposals$status == "approved"))
})

test_that("implementation prompt uses approved workflow only when proposals exist", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Approved workflow only")
  scaffolder$decompose_task(candidates = c("Approved step"))

  scaffolder$propose_workflow(
    new_workflow_spec(
      nodes = rbind(
        workflow_node("node_1", "Proposed step"),
        workflow_node("node_2", "Unapproved review")
      ),
      edges = workflow_edge("node_1", "node_2"),
      task = "Approved workflow only"
    ),
    notes = "Not approved yet"
  )

  prompt_json <- build_implementation_prompt(scaffolder, language = "R")

  expect_true(grepl("\"Approved step\"", prompt_json, fixed = TRUE))
  expect_false(grepl("\"Unapproved review\"", prompt_json, fixed = TRUE))
})

test_that("preview_scaffolder_message stores proposals without mutating live workflow", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Preview only")
  scaffolder$decompose_task(candidates = c("Current approved step"))

  preview <- preview_scaffolder_message(
    scaffolder,
    list(actions = list(
      list(method = "edit_workflow", args = list(
        add = list(list(label = "Previewed proposal node"))
      ))
    ))
  )

  expect_true(any(scaffolder$workflow$nodes$label == "Current approved step"))
  expect_false(any(scaffolder$workflow$nodes$label == "Previewed proposal node"))
  expect_true(any(preview$workflow_after$nodes$label == "Previewed proposal node"))
  expect_true(identical(
    scaffolder$get_workflow_proposal(preview$proposal_id)$status,
    "pending"
  ))
})

test_that("workflow proposal persistence and graph helpers round-trip proposal objects", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Persist proposal")

  proposal <- scaffolder$propose_workflow(
    new_workflow_spec(
      nodes = rbind(
        workflow_node("node_1", "Draft"),
        workflow_node("node_2", "Review")
      ),
      edges = workflow_edge("node_1", "node_2"),
      task = "Persist proposal"
    )
  )

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  save_workflow_proposal(proposal, path)
  loaded <- load_workflow_proposal(path)
  graph_data <- workflow_proposal_graph_data(loaded)

  expect_s3_class(loaded, "agentr_workflow_proposal")
  expect_true(identical(loaded$id, proposal$id))
  expect_true(identical(loaded$status, "pending"))
  expect_true(identical(nrow(graph_data$vertices), 2L))
  expect_true(identical(nrow(graph_data$edges), 1L))
})

test_that("invalid workflow proposal transitions fail clearly", {
  proposal <- new_workflow_proposal(
    id = "proposal_1",
    workflow = new_workflow_spec(
      nodes = workflow_node("node_1", "Only step"),
      edges = .empty_workflow_edges(),
      task = "Invalid transitions"
    )
  )
  proposal <- transition_workflow_proposal(proposal, "approved")

  expect_error(
    transition_workflow_proposal(proposal, "under_discussion"),
    "Invalid workflow proposal transition"
  )
})

test_that("validate_scaffolder_message rejects unsupported methods", {
  message <- list(
    actions = list(
      list(method = "run_arbitrary_code", args = list())
    )
  )

  expect_error(
    validate_scaffolder_message(message),
    "Unsupported scaffolder method"
  )
})

test_that("workflow_graph_data returns igraph-ready vertices and edges", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Visualize a workflow")
  scaffolder$decompose_task(candidates = c("Clarify", "Translate"))

  graph_data <- workflow_graph_data(scaffolder)

  expect_true(is.list(graph_data))
  expect_true(identical(names(graph_data), c("vertices", "edges")))
  expect_true(identical(nrow(graph_data$vertices), 2L))
  expect_true(identical(nrow(graph_data$edges), 1L))
  expect_true(all(c("from", "to") %in% names(graph_data$edges)))
  expect_true(all(c("node_label", "node_shape", "node_color", "node_border") %in% names(graph_data$vertices)))
  expect_true("edge_label" %in% names(graph_data$edges))
})

test_that("validate_scaffolder_message enforces method-specific arguments", {
  expect_error(
    validate_scaffolder_message(list(
      actions = list(list(method = "evaluate_task", args = list()))
    )),
    "requires a non-empty `task` string"
  )

  expect_error(
    validate_scaffolder_message(list(
      actions = list(list(method = "ask_human_changes", args = list(node_id = "node_1")))
    )),
    "Unsupported argument\\(s\\) for method `ask_human_changes`"
  )

  expect_error(
    validate_scaffolder_message(list(
      actions = list(list(
        method = "review_node",
        args = list(node_id = "node_1", confidence = 1.2)
      ))
    )),
    "Confidence values must be numeric in \\[0, 1\\]"
  )

  expect_error(
    validate_scaffolder_message(list(
      actions = list(list(
        method = "edit_workflow",
        args = list(add = list(list(confidence = 0.5)))
      ))
    )),
    "must include a non-empty `label`"
  )
})

test_that("apply_scaffolder_message validates node references against state", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Validate references")
  scaffolder$decompose_task(candidates = c("Clarify", "Translate"))

  expect_error(
    apply_scaffolder_message(
      scaffolder,
      list(actions = list(list(
        method = "ask_human_rule",
        args = list(node_id = "node_99")
      )))
    ),
    "Unknown workflow node reference"
  )

  expect_error(
    apply_scaffolder_message(
      scaffolder,
      list(actions = list(list(
        method = "edit_workflow",
        args = list(
          remove = list("node_1"),
          rule_specs = list(node_1 = "Removed node")
        )
      )))
    ),
    "references unknown or removed node ids"
  )
})

test_that("collect_scaffolder_questions extracts human prompts from dispatch results", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Collect human questions")
  scaffolder$decompose_task(candidates = c("Clarify", "Need rule"))

  result <- apply_scaffolder_message(
    scaffolder,
    list(actions = list(
      list(method = "ask_human_rule", args = list(node_id = "node_2")),
      list(method = "ask_human_changes", args = list())
    ))
  )

  questions <- collect_scaffolder_questions(scaffolder, result)

  expect_true(identical(nrow(questions), 2L))
  expect_true(all(c("method", "question") %in% names(questions)))
  expect_true(any(questions$method == "ask_human_rule"))
})

test_that("apply_scaffolder_message can collect errors when stop_on_error is false", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Non-fatal errors")
  scaffolder$decompose_task(candidates = c("Clarify"))

  result <- apply_scaffolder_message(
    scaffolder,
    list(actions = list(
      list(method = "ask_human_rule", args = list(node_id = "node_99")),
      list(method = "ask_human_changes", args = list())
    )),
    stop_on_error = FALSE
  )

  expect_true(identical(length(result$errors), 1L))
  expect_true(identical(length(result$human_prompts), 1L))
  expect_true(identical(result$applied_actions[[1]]$status, "error"))
  expect_true(identical(result$applied_actions[[2]]$status, "applied"))
})

test_that("edit_workflow supports edge insertion and removal", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Edit graph edges")
  scaffolder$decompose_task(candidates = c("Start", "Finish"))

  scaffolder$edit_workflow(
    insert = list(list(
      node = list(id = "node_mid", label = "Review"),
      between = list("node_1", "node_2")
    )),
    remove_edges = list(list(from = "node_1", to = "node_2"))
  )

  spec <- scaffolder$workflow_spec()

  expect_true("node_mid" %in% spec$nodes$id)
  expect_false(any(spec$edges$from == "node_1" & spec$edges$to == "node_2"))
  expect_true(any(spec$edges$from == "node_1" & spec$edges$to == "node_mid"))
  expect_true(any(spec$edges$from == "node_mid" & spec$edges$to == "node_2"))
})

test_that("apply_scaffolder_message accepts direct decompose_task nodes and label edges", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Design onboarding workflow")

  rs1 <- '{
    "actions": [
      {
        "method": "discuss_task",
        "args": {
          "feedback": "Initial discussion: onboarding should cover logistics, access, training, and QA.",
          "source": "model"
        }
      },
      {
        "method": "decompose_task",
        "args": {
          "nodes": [
            {"label": "Receive equipment", "confidence": 0.95, "human_required": true},
            {"label": "Complete HR paperwork", "confidence": 0.95, "human_required": true},
            {"label": "Set up system access", "confidence": 0.9, "human_required": false},
            {"label": "Attend orientation", "confidence": 0.9, "human_required": true}
          ],
          "edges": [
            {"from": "Receive equipment", "to": "Complete HR paperwork"},
            {"from": "Receive equipment", "to": "Set up system access"},
            {"from": "Set up system access", "to": "Attend orientation"}
          ]
        }
      }
    ]
  }'

  out <- apply_scaffolder_message(scaffolder, rs1)
  spec <- out$workflow_after

  expect_true(identical(nrow(spec$nodes), 4L))
  expect_true(identical(nrow(spec$edges), 3L))
  expect_true(all(spec$edges$from %in% spec$nodes$id))
  expect_true(all(spec$edges$to %in% spec$nodes$id))
  expect_true(identical(length(spec$metadata$discussion_rounds), 1L))
  expect_true(any(spec$nodes$label == "Receive equipment"))
})

test_that("dispatch normalizes direct decompose_task args for legacy method signatures", {
  legacy_scaffolder <- list(
    decompose_task = function(task = NULL, candidates = NULL, suggestions = NULL) {
      NULL
    }
  )

  args <- list(
    nodes = list(
      list(label = "Receive equipment"),
      list(label = "Complete HR paperwork")
    ),
    edges = list(
      list(from = "Receive equipment", to = "Complete HR paperwork")
    )
  )

  normalized <- agentr:::.normalize_dispatch_args(legacy_scaffolder, "decompose_task", args)

  expect_true(is.null(normalized$nodes))
  expect_true(is.null(normalized$edges))
  expect_true(is.list(normalized$suggestions))
  expect_true(identical(length(normalized$suggestions$nodes), 2L))
  expect_true(identical(length(normalized$suggestions$edges), 1L))
})
