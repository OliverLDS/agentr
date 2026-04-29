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

  if (inherits(x, "IntelligentAgent")) {
    x$validate()
    x <- x$spec
  }

  if (inherits(x, "AgentSpec")) {
    x$validate()
    workflow <- x$workflow
    if (is.null(workflow)) {
      workflow <- new_workflow_spec(
        nodes = .empty_workflow_nodes(),
        edges = .empty_workflow_edges(),
        task = x$task
      )
    }
    return(list(
      task = x$task,
      agent_name = x$agent_name,
      selected_subsystems = x$selected_subsystems(),
      node_subsystems = if (is.null(x$metadata$node_subsystems)) list() else x$metadata$node_subsystems,
      nodes = workflow$nodes[, c("id", "label", "rule_spec", "implementation_hint", "knowledge_refs"), drop = FALSE],
      human_required = workflow$nodes[workflow$nodes$human_required, "id", drop = TRUE],
      knowledge_spec = x$knowledge_spec
    ))
  }

  if (inherits(x, "agentr_workflow_spec")) {
    validate_workflow_spec(x)
    return(list(
      task = x$task,
      agent_name = NA_character_,
      selected_subsystems = character(),
      node_subsystems = list(),
      nodes = x$nodes[, c("id", "label", "rule_spec", "implementation_hint", "knowledge_refs"), drop = FALSE],
      human_required = x$nodes[x$nodes$human_required, "id", drop = TRUE],
      knowledge_spec = NULL
    ))
  }

  if (is.list(x) && all(c("task", "nodes", "human_required") %in% names(x))) {
    if (is.null(x$agent_name)) x$agent_name <- NA_character_
    if (is.null(x$selected_subsystems)) x$selected_subsystems <- character()
    if (is.null(x$node_subsystems)) x$node_subsystems <- list()
    if (is.null(x$knowledge_spec)) x$knowledge_spec <- NULL
    return(x)
  }

  stop(
    paste(
      "`x` must be a Scaffolder, IntelligentAgent, AgentSpec,",
      "an `agentr_workflow_spec`, or an implementation spec list."
    ),
    call. = FALSE
  )
}

#' Build an implementation prompt for a coding agent
#'
#' Creates a second-stage prompt that turns workflow scaffolding output into an
#' implementation-oriented handoff for a coding agent such as Codex.
#'
#' @param x A [`Scaffolder`] instance, workflow specification, or
#'   implementation-spec-like list. `AgentSpec` and `IntelligentAgent`
#'   inputs are also supported.
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
#' @param include_knowledge Whether approved knowledge should be included in the
#'   implementation handoff when available.
#' @param knowledge_scope Knowledge-selection scope when `include_knowledge` is
#'   `TRUE`: referenced items only, all approved items, or all items.
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
  extra_context = list(),
  include_knowledge = TRUE,
  knowledge_scope = c("referenced", "approved", "all")
) {
  format <- match.arg(format, choices = c("json", "markdown"))
  knowledge_scope <- match.arg(knowledge_scope)
  contract <- new_prompt_contract(
    input_type = "Scaffolder|IntelligentAgent|AgentSpec|agentr_workflow_spec|implementation_spec_list",
    target_role = "implementation_planner",
    expected_output = "JSON object with `implementation_plan`."
  )

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
  if (!is.logical(include_knowledge) || length(include_knowledge) != 1L || is.na(include_knowledge)) {
    stop("`include_knowledge` must be a single non-missing logical value.", call. = FALSE)
  }

  spec <- .normalize_implementation_prompt_input(x)
  workflow_payload <- spec
  workflow_payload$knowledge_spec <- NULL
  knowledge_payload <- NULL
  if (isTRUE(include_knowledge) && inherits(spec$knowledge_spec, "KnowledgeSpec")) {
    items <- spec$knowledge_spec$list_items()
    if (identical(knowledge_scope, "referenced")) {
      refs <- unique(unlist(spec$nodes$knowledge_refs, use.names = FALSE))
      refs <- refs[nzchar(refs)]
      items <- Filter(function(item) item$id %in% refs && identical(item$review$status, "approved"), items)
    } else if (identical(knowledge_scope, "approved")) {
      items <- Filter(function(item) identical(item$review$status, "approved"), items)
    }
    knowledge_payload <- lapply(items, function(item) {
      list(
        id = item$id,
        type = item$type,
        normalized_statement = item$normalized_statement,
        conditions = item$conditions,
        exceptions = item$exceptions,
        review = item$review
      )
    })
  }
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

  payload <- .prompt_contract_payload(contract, list(
    role = "implementation_planner",
    target_agent = target_agent,
    target_language = language,
    runtime = runtime,
    style = style,
    constraints = as.list(constraints),
    workflow = workflow_payload,
    knowledge = knowledge_payload,
    extra_context = extra_context,
    instructions = c(
      "Translate the workflow into an implementation-ready coding plan.",
      "Respect node ordering, dependencies, and human-required checkpoints.",
      "Use approved knowledge references when they are present and relevant to specific workflow nodes.",
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
  ))

  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }

  workflow_json <- jsonlite::toJSON(
    workflow_payload,
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
    "## Knowledge Input",
    if (is.null(knowledge_payload)) "<none>" else paste(c("```json", jsonlite::toJSON(knowledge_payload, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"), "```"), collapse = "\n"),
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
  contract <- new_prompt_contract(
    input_type = "character code context",
    target_role = "workflow_extractor",
    expected_output = "Workflow specification JSON with `task`, `nodes`, `edges`, and `metadata`."
  )

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

  payload <- .prompt_contract_payload(contract, list(
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
  ))

  if (identical(format, "json")) {
    return(.prompt_json(payload))
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

#' Build a workflow extraction prompt from an article
#'
#' Creates a prompt for a reasoning model to infer one or more
#' `agentr`-compatible workflow specifications from an article describing
#' agentic AI application cases, demonstrations, or methods.
#'
#' @param article_context Character string or character vector containing the
#'   article text, excerpt, URL, abstract, notes, or section summaries.
#' @param article_title Optional article title.
#' @param task Optional task summary for the extraction.
#' @param case_names Optional case names to prioritize when extracting
#'   workflows.
#' @param extraction_mode Extraction mode: `"case_workflows"`,
#'   `"global_workflow"`, or `"both"`.
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
build_article_workflow_extraction_prompt <- function(
  article_context,
  article_title = NULL,
  task = NULL,
  case_names = NULL,
  extraction_mode = "both",
  format = "json",
  target_agent = "reasoning_model",
  extraction_goal = "Infer workflow specification(s) from article-described agentic AI application case(s), consistent with agentr.",
  constraints = character(),
  extra_context = list()
) {
  extraction_mode <- match.arg(extraction_mode, choices = c("case_workflows", "global_workflow", "both"))
  format <- match.arg(format, choices = c("json", "markdown"))

  contract <- new_prompt_contract(
    input_type = "character article context",
    target_role = "article_workflow_extractor",
    expected_output = paste(
      "JSON containing one or more workflow specifications grounded in article case(s),",
      "with top-level fields `article_task`, `workflows`, `cross_case_summary`, and `metadata`."
    )
  )

  if (!is.character(article_context) || !length(article_context) || any(!nzchar(article_context))) {
    stop("`article_context` must be a non-empty character vector.", call. = FALSE)
  }
  if (!is.null(article_title) && (!is.character(article_title) || length(article_title) != 1L || !nzchar(article_title))) {
    stop("`article_title` must be NULL or a non-empty string.", call. = FALSE)
  }
  if (!is.null(task) && (!is.character(task) || length(task) != 1L || !nzchar(task))) {
    stop("`task` must be NULL or a non-empty string.", call. = FALSE)
  }
  if (!is.null(case_names) && (!is.character(case_names) || !length(case_names) || any(!nzchar(case_names)))) {
    stop("`case_names` must be NULL or a non-empty character vector.", call. = FALSE)
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

  article_text <- paste(article_context, collapse = "\n\n")
  inferred_task <- task %||% "Infer workflow specification(s) from the article's agentic AI application case(s)."

  response_schema <- list(
    article_task = inferred_task,
    workflows = list(
      list(
        workflow_id = "case_1_workflow",
        case_id = "case_1",
        case_label = "Case name or short label",
        workflow_scope = "case",
        task = "Workflow goal inferred from the case",
        confidence = 0.86,
        evidence = list(
          list(
            section = "Optional article section heading",
            span = "Short supporting excerpt or paraphrased evidence",
            rationale = "Why this evidence supports the workflow"
          )
        ),
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
            review_confidence = 0.80
          )
        ),
        edges = list(
          list(
            from = "node_1",
            to = "node_2",
            relation = "depends_on",
            confidence = 0.80,
            notes = "Optional edge note"
          )
        ),
        metadata = list(
          source = "article_case_workflow_extraction",
          case_type = "agentic_ai_application",
          agent_roles = list("planner", "executor", "reviewer"),
          assumptions = list("Optional assumption")
        )
      )
    ),
    cross_case_summary = list(
      shared_patterns = list("Optional shared workflow pattern"),
      key_variations = list("Optional variation across cases"),
      reusable_template = list(
        task = "Optional generalized workflow task",
        nodes = list(
          list(
            id = "node_1",
            label = "Generalized step",
            confidence = 0.70,
            human_required = TRUE,
            rule_spec = "Optional generalized rule",
            implementation_hint = "Optional generalized implementation hint",
            complete = FALSE,
            review_status = "pending",
            review_notes = "Optional note",
            review_confidence = 0.70
          )
        ),
        edges = list(
          list(
            from = "node_1",
            to = "node_2",
            relation = "depends_on",
            confidence = 0.70,
            notes = "Optional note"
          )
        )
      )
    ),
    metadata = list(
      source = "article_workflow_extraction",
      article_title = article_title,
      extraction_goal = extraction_goal,
      extraction_mode = extraction_mode,
      assumptions = list("Optional assumption")
    )
  )

  instructions <- c(
    "Read the article as a description of one or more agentic AI application cases.",
    "Infer workflow specification(s) that are consistent with agentr workflow-spec conventions.",
    "If the article contains multiple cases, extract one workflow per case whenever the cases are substantively distinct.",
    "If the article mainly presents one overarching pattern, also extract a reusable generalized workflow when supported by the text.",
    "Use stable node ids such as `node_1`, `node_2`, and express dependencies through `edges`.",
    "Capture human-required checkpoints, governing rules, review loops, and implementation hints when supported by the article.",
    "Distinguish clearly between explicit article evidence and reasonable inference.",
    "Ground each workflow in article evidence using short spans, section names, or concise paraphrases.",
    "Do not invent major steps, tools, or agent roles that are not reasonably supported by the article or extra context.",
    "When the article is ambiguous, use lower confidence values and record assumptions in workflow metadata and top-level metadata."
  )
  if (!is.null(case_names)) {
    instructions <- c(
      instructions,
      paste0("Prioritize extraction around these named cases if present: ", paste(case_names, collapse = ", "), ".")
    )
  }
  if (identical(extraction_mode, "case_workflows")) {
    instructions <- c(instructions, "Return only case-specific workflows and keep `cross_case_summary` minimal.")
  }
  if (identical(extraction_mode, "global_workflow")) {
    instructions <- c(instructions, "Focus on one generalized workflow for the whole article; only split into multiple workflows if the article makes the separation unavoidable.")
  }
  if (identical(extraction_mode, "both")) {
    instructions <- c(instructions, "Return both case-specific workflows and a concise cross-case synthesis when supported by the article.")
  }

  payload <- .prompt_contract_payload(contract, list(
    role = "article_workflow_extractor",
    target_agent = target_agent,
    extraction_goal = extraction_goal,
    article_title = article_title,
    task = inferred_task,
    case_names = if (is.null(case_names)) NULL else as.list(case_names),
    extraction_mode = extraction_mode,
    constraints = as.list(constraints),
    article_context = article_context,
    extra_context = extra_context,
    instructions = instructions,
    response_requirements = list(
      format = "json",
      rules = c(
        "Return machine-readable JSON only.",
        "Return a top-level object with `article_task`, `workflows`, `cross_case_summary`, and `metadata`.",
        "Each element of `workflows` must contain `task`, `nodes`, `edges`, and `metadata`.",
        "Node and edge shapes should remain compatible with agentr workflow-spec conventions.",
        "Use empty arrays or minimal placeholders rather than omitting top-level required fields."
      ),
      schema = response_schema
    )
  ))

  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }

  schema_json <- jsonlite::toJSON(
    response_schema,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )

  paste(
    "# Article Workflow Extraction Prompt",
    "",
    "You are extracting workflow specification(s) from an article that describes one or more agentic AI application cases.",
    paste0("Target reasoning agent: `", target_agent, "`."),
    if (is.null(article_title)) "Article title: <unspecified>" else paste0("Article title: `", article_title, "`."),
    paste0("Extraction mode: `", extraction_mode, "`."),
    "Your job is to infer the workflow(s) embodied in the article and express them in a structure compatible with agentr.",
    "",
    "## Extraction Goal",
    extraction_goal,
    "",
    "## Task",
    inferred_task,
    "",
    "## Named Cases",
    if (is.null(case_names)) "<unspecified>" else paste(case_names, collapse = ", "),
    "",
    "## Instructions",
    paste(paste0("- ", instructions), collapse = "\n"),
    "",
    "## Constraints",
    if (length(constraints)) paste(paste0("- ", constraints), collapse = "\n") else "- <none>",
    "",
    "## Article Context",
    "```text",
    article_text,
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
    "- Return a top-level object with `article_task`, `workflows`, `cross_case_summary`, and `metadata`.",
    "- Each workflow should preserve the agentr-style node/edge structure.",
    "",
    "## Expected JSON Shape",
    "```json",
    schema_json,
    "```",
    sep = "\n"
  )
}
