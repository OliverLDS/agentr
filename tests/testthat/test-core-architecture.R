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

test_that("Scaffolder produces workflow specs and applies human feedback", {
  agent <- AgentCore$new()
  scaffolder <- Scaffolder$new(agent = agent)

  scaffolder$evaluate_task("Design a workflow")
  scaffolder$decompose_task(candidates = c("Clarify", "Plan", "Translate"))
  scaffolder$apply_human_feedback(
    completeness = list(node_1 = TRUE),
    rule_specs = list(node_2 = "Require approval before branching"),
    confidence = list(node_3 = 0.4)
  )

  spec <- scaffolder$workflow_spec()

  expect_s3_class(spec, "agentr_workflow_spec")
  expect_true(identical(nrow(spec$nodes), 3L))
  expect_true(spec$nodes$complete[spec$nodes$id == "node_1"])
  expect_true(identical(
    spec$nodes$rule_spec[spec$nodes$id == "node_2"],
    "Require approval before branching"
  ))
  expect_true(isTRUE(all.equal(
    spec$nodes$confidence[spec$nodes$id == "node_3"],
    0.4
  )))
  expect_true(identical(nrow(scaffolder$low_confidence_nodes()), 1L))
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
  expect_true(grepl("# Scaffolding Reasoning Prompt", prompt_markdown, fixed = TRUE))
  expect_true(grepl("## Available Scaffolder Methods", prompt_markdown, fixed = TRUE))
  expect_true(grepl("apply_human_feedback", prompt_markdown, fixed = TRUE))
  expect_true(grepl("machine-readable JSON only", prompt_markdown, fixed = TRUE))
  expect_true(grepl("Ask the human only when ambiguity, missing rules, or completion checks block progress", prompt_markdown, fixed = TRUE))
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

test_that("apply_scaffolder_message dispatches actions to scaffolder methods", {
  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  message <- list(
    actions = list(
      list(
        method = "evaluate_task",
        args = list(task = "Draft a workflow")
      ),
      list(
        method = "decompose_task",
        args = list(candidates = list("Clarify", "Translate"))
      ),
      list(
        method = "apply_human_feedback",
        args = list(
          confidence = list(node_1 = 0.9),
          rule_specs = list(node_2 = "Require a final review")
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
  expect_true(identical(length(out$applied_actions), 3L))
  expect_true(identical(scaffolder$task, "Draft a workflow"))
  expect_true(identical(nrow(scaffolder$workflow$nodes), 2L))
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
        method = "apply_human_feedback",
        args = list(confidence = list(node_1 = 1.2))
      ))
    )),
    "values must be numeric in \\[0, 1\\]"
  )

  expect_error(
    validate_scaffolder_message(list(
      actions = list(list(
        method = "apply_human_feedback",
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
        method = "apply_human_feedback",
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
