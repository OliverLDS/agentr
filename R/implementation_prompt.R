#' Normalize implementation prompt input
#'
#' @param x A [`Scaffolder`] instance, workflow specification, or
#'   implementation-spec-like list.
#'
#' @return A normalized implementation payload list.
#' @keywords internal
.normalize_implementation_prompt_input <- function(x) {
  if (inherits(x, "Scaffolder")) {
    return(x$implementation_spec())
  }

  if (inherits(x, "agentr_workflow_spec")) {
    validate_workflow_spec(x)
    return(list(
      task = x$task,
      nodes = x$nodes[, c("id", "label", "rule_spec", "implementation_hint"), drop = FALSE],
      human_required = x$nodes[x$nodes$human_required, "id", drop = TRUE]
    ))
  }

  if (is.list(x) && all(c("task", "nodes", "human_required") %in% names(x))) {
    return(x)
  }

  stop(
    "`x` must be a Scaffolder, an `agentr_workflow_spec`, or an implementation spec list.",
    call. = FALSE
  )
}

#' Build an implementation prompt for a coding agent
#'
#' Creates a second-stage prompt that turns workflow scaffolding output into an
#' implementation-oriented handoff for a coding agent such as Codex.
#'
#' @param x A [`Scaffolder`] instance, workflow specification, or
#'   implementation-spec-like list.
#' @param language Target implementation language, for example `"R"` or
#'   `"Python"`.
#' @param format Prompt payload format. Use `"json"` for SDK-facing structured
#'   payloads and `"markdown"` for prompts that a human may paste into a coding
#'   chat interface.
#' @param target_agent Target coding agent label.
#' @param runtime Optional runtime or framework note.
#' @param style Optional implementation style note.
#' @param constraints Optional character vector of implementation constraints.
#' @param extra_context Optional named list of additional context.
#'
#' @return Character string prompt.
#' @export
build_implementation_prompt <- function(
  x,
  language,
  format = "json",
  target_agent = "codex",
  runtime = NULL,
  style = NULL,
  constraints = character(),
  extra_context = list()
) {
  format <- match.arg(format, choices = c("json", "markdown"))

  if (!is.character(language) || length(language) != 1L || !nzchar(language)) {
    stop("`language` must be a non-empty string.", call. = FALSE)
  }
  if (!is.character(target_agent) || length(target_agent) != 1L || !nzchar(target_agent)) {
    stop("`target_agent` must be a non-empty string.", call. = FALSE)
  }
  if (!is.null(runtime) && (!is.character(runtime) || length(runtime) != 1L)) {
    stop("`runtime` must be NULL or a single string.", call. = FALSE)
  }
  if (!is.null(style) && (!is.character(style) || length(style) != 1L)) {
    stop("`style` must be NULL or a single string.", call. = FALSE)
  }
  if (!is.character(constraints)) {
    stop("`constraints` must be a character vector.", call. = FALSE)
  }
  if (!is.list(extra_context)) {
    stop("`extra_context` must be a list.", call. = FALSE)
  }

  spec <- .normalize_implementation_prompt_input(x)
  response_schema <- list(
    implementation_plan = list(
      summary = "Short implementation objective.",
      files = list(
        list(
          path = "R/example.R",
          purpose = "Why this file is needed.",
          changes = list("Concrete change 1", "Concrete change 2")
        )
      ),
      tests = list("Describe validation or test additions."),
      risks = list("List material implementation risks or blockers.")
    )
  )

  payload <- list(
    role = "implementation_planner",
    target_agent = target_agent,
    target_language = language,
    runtime = runtime,
    style = style,
    constraints = as.list(constraints),
    workflow = spec,
    extra_context = extra_context,
    instructions = c(
      "Translate the workflow into an implementation-ready coding plan.",
      "Respect node ordering, dependencies, and human-required checkpoints.",
      "Propose concrete files, modules, tests, and validation steps.",
      "Do not invent external systems or runtime assumptions unless they are justified by the workflow or extra context.",
      "Keep the plan actionable for a coding agent that will implement code next."
    ),
    response_requirements = list(
      format = "json",
      rules = c(
        "Return machine-readable JSON only.",
        "The top-level object must contain `implementation_plan`.",
        "Each planned file should include `path`, `purpose`, and `changes`."
      ),
      schema = response_schema
    )
  )

  if (identical(format, "json")) {
    return(jsonlite::toJSON(
      payload,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    ))
  }

  workflow_json <- jsonlite::toJSON(
    spec,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )
  schema_json <- jsonlite::toJSON(
    response_schema,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )

  paste(
    "# Implementation Planning Prompt",
    "",
    "You are preparing an implementation-ready coding plan for a workflow-driven task.",
    paste0("Target coding agent: `", target_agent, "`."),
    paste0("Target language: `", language, "`."),
    if (is.null(runtime)) "Runtime: <unspecified>" else paste0("Runtime: `", runtime, "`."),
    if (is.null(style)) "Style: <unspecified>" else paste0("Style: `", style, "`."),
    "",
    "## Instructions",
    "- Translate the workflow into an implementation-ready coding plan.",
    "- Respect node ordering, dependencies, and human-required checkpoints.",
    "- Propose concrete files, modules, tests, and validation steps.",
    "- Do not invent external systems or runtime assumptions unless justified by the workflow or extra context.",
    "- Keep the plan actionable for a coding agent that will implement code next.",
    "",
    "## Constraints",
    if (length(constraints)) paste(paste0("- ", constraints), collapse = "\n") else "- <none>",
    "",
    "## Workflow Input",
    "```json",
    workflow_json,
    "```",
    "",
    "## Extra Context",
    if (length(extra_context)) {
      jsonlite::toJSON(extra_context, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null")
    } else {
      "<none>"
    },
    "",
    "## Response Requirements",
    "- Respond with machine-readable JSON only.",
    "- The top-level object must contain `implementation_plan`.",
    "- Each planned file should include `path`, `purpose`, and `changes`.",
    "",
    "## Expected JSON Shape",
    "```json",
    schema_json,
    "```",
    sep = "\n"
  )
}

#' Build a workflow extraction prompt from existing code
#'
#' Creates a prompt for a reasoning model to infer an `agentr`-compatible
#' workflow specification from ad hoc code, scripts, or module summaries that
#' already exist.
#'
#' @param code_context Character string or character vector describing the
#'   existing code, snippets, file summaries, or execution flow to inspect.
#' @param task Optional task summary associated with the code.
#' @param language Optional source-code language, for example `"R"` or
#'   `"Python"`.
#' @param format Prompt payload format. Use `"json"` for SDK-facing structured
#'   payloads and `"markdown"` for prompts pasted into a reasoning-model chat
#'   interface.
#' @param target_agent Target reasoning agent label.
#' @param extraction_goal Optional extraction goal note.
#' @param constraints Optional character vector of extraction constraints.
#' @param extra_context Optional named list of additional context.
#'
#' @return Character string prompt.
#' @export
build_workflow_extraction_prompt <- function(
  code_context,
  task = NULL,
  language = NULL,
  format = "json",
  target_agent = "reasoning_model",
  extraction_goal = "Infer a workflow specification consistent with agentr.",
  constraints = character(),
  extra_context = list()
) {
  format <- match.arg(format, choices = c("json", "markdown"))

  if (!is.character(code_context) || !length(code_context) || any(!nzchar(code_context))) {
    stop("`code_context` must be a non-empty character vector.", call. = FALSE)
  }
  if (!is.null(task) && (!is.character(task) || length(task) != 1L || !nzchar(task))) {
    stop("`task` must be NULL or a non-empty string.", call. = FALSE)
  }
  if (!is.null(language) && (!is.character(language) || length(language) != 1L || !nzchar(language))) {
    stop("`language` must be NULL or a non-empty string.", call. = FALSE)
  }
  if (!is.character(target_agent) || length(target_agent) != 1L || !nzchar(target_agent)) {
    stop("`target_agent` must be a non-empty string.", call. = FALSE)
  }
  if (!is.character(extraction_goal) || length(extraction_goal) != 1L || !nzchar(extraction_goal)) {
    stop("`extraction_goal` must be a non-empty string.", call. = FALSE)
  }
  if (!is.character(constraints)) {
    stop("`constraints` must be a character vector.", call. = FALSE)
  }
  if (!is.list(extra_context)) {
    stop("`extra_context` must be a list.", call. = FALSE)
  }

  code_text <- paste(code_context, collapse = "\n\n")
  response_schema <- list(
    task = task %||% "Inferred workflow task summary.",
    nodes = list(
      list(
        id = "node_1",
        label = "Describe workflow step",
        confidence = 0.85,
        human_required = TRUE,
        rule_spec = "Optional governing rule",
        implementation_hint = "Optional implementation hint",
        complete = FALSE,
        review_status = "pending",
        review_notes = "Optional review note",
        review_confidence = 0.8
      )
    ),
    edges = list(
      list(
        from = "node_1",
        to = "node_2",
        relation = "depends_on",
        confidence = 0.8,
        notes = "Optional edge note"
      )
    ),
    metadata = list(
      source = "workflow_extraction",
      extraction_goal = extraction_goal,
      assumptions = list("Optional assumption")
    )
  )

  instructions <- c(
    "Infer the workflow already implemented by the provided code context.",
    "Return a workflow specification whose shape is consistent with agentr workflow specs.",
    "Use stable node ids such as `node_1`, `node_2`, and express dependencies through `edges`.",
    "Capture human-required checkpoints, governing rules, and implementation hints when supported by the code context.",
    "Do not invent major workflow steps that are not grounded in the provided code or extra context.",
    "When the code is ambiguous, use lower confidence values and explain assumptions in `metadata`."
  )

  payload <- list(
    role = "workflow_extractor",
    target_agent = target_agent,
    extraction_goal = extraction_goal,
    task = task,
    source_language = language,
    constraints = as.list(constraints),
    code_context = code_context,
    extra_context = extra_context,
    instructions = instructions,
    response_requirements = list(
      format = "json",
      rules = c(
        "Return machine-readable JSON only.",
        "Return a top-level workflow specification object, not scaffolder actions.",
        "The object must contain `task`, `nodes`, `edges`, and `metadata`.",
        "Node and edge shapes should match agentr workflow-spec conventions."
      ),
      schema = response_schema
    )
  )

  if (identical(format, "json")) {
    return(jsonlite::toJSON(
      payload,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    ))
  }

  schema_json <- jsonlite::toJSON(
    response_schema,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )

  paste(
    "# Workflow Extraction Prompt",
    "",
    "You are reverse-engineering an existing implementation into an `agentr` workflow specification.",
    paste0("Target reasoning agent: `", target_agent, "`."),
    if (is.null(language)) "Source language: <unspecified>" else paste0("Source language: `", language, "`."),
    "Your job is to infer the workflow already embodied in the code context below.",
    "",
    "## Extraction Goal",
    extraction_goal,
    "",
    "## Task",
    if (is.null(task)) "<unspecified>" else task,
    "",
    "## Instructions",
    paste(paste0("- ", instructions), collapse = "\n"),
    "",
    "## Constraints",
    if (length(constraints)) paste(paste0("- ", constraints), collapse = "\n") else "- <none>",
    "",
    "## Code Context",
    "```text",
    code_text,
    "```",
    "",
    "## Extra Context",
    if (length(extra_context)) {
      jsonlite::toJSON(extra_context, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null")
    } else {
      "<none>"
    },
    "",
    "## Response Requirements",
    "- Produce the response as a downloadable `.json` file or attachment link when the UI supports it.",
    "- If file output is unavailable, return raw machine-readable JSON only.",
    "- Return a top-level workflow specification object, not scaffolder actions.",
    "- The object must contain `task`, `nodes`, `edges`, and `metadata`.",
    "",
    "## Expected JSON Shape",
    "```json",
    schema_json,
    "```",
    sep = "\n"
  )
}
