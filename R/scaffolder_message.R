#' List LLM-callable scaffolder methods
#'
#' Returns the method names that an external reasoning system is allowed to
#' request through a machine-readable scaffolding message.
#'
#' @return Character vector of allowed method names.
#' @export
scaffolder_action_methods <- function() {
  c(
    "evaluate_task",
    "decompose_task",
    "ask_human_complete",
    "ask_human_changes",
    "ask_human_rule",
    "apply_human_feedback"
  )
}

#' Validate scaffolder action arguments for a specific method
#'
#' @param method Scaffolder method name.
#' @param args Named list of action arguments.
#'
#' @return Validated argument list, invisibly.
#' @keywords internal
.validate_scaffolder_action_args <- function(method, args) {
  if (is.null(args)) {
    args <- list()
  }
  if (!is.list(args)) {
    stop("Each action `args` field must be a list.", call. = FALSE)
  }

  known_args <- switch(
    method,
    evaluate_task = c("task"),
    decompose_task = c("task", "candidates"),
    ask_human_complete = c("node_id"),
    ask_human_changes = character(),
    ask_human_rule = c("node_id"),
    apply_human_feedback = c("completeness", "add", "remove", "rule_specs", "confidence"),
    stop("Unsupported scaffolder method: ", method, call. = FALSE)
  )

  extra_args <- setdiff(names(args), known_args)
  if (length(extra_args)) {
    stop(
      "Unsupported argument(s) for method `", method, "`: ",
      paste(extra_args, collapse = ", "),
      call. = FALSE
    )
  }

  if (identical(method, "evaluate_task")) {
    if (!is.character(args$task) || length(args$task) != 1L || !nzchar(args$task)) {
      stop("`evaluate_task` requires a non-empty `task` string.", call. = FALSE)
    }
  }

  if (identical(method, "decompose_task")) {
    if (!is.null(args$task) &&
        (!is.character(args$task) || length(args$task) != 1L || !nzchar(args$task))) {
      stop("`decompose_task.task` must be a non-empty string when provided.", call. = FALSE)
    }
    if (!is.null(args$candidates)) {
      if (!is.list(args$candidates) && !is.character(args$candidates)) {
        stop("`decompose_task.candidates` must be a character vector or list.", call. = FALSE)
      }
      candidate_values <- unlist(args$candidates, use.names = FALSE)
      if (!is.character(candidate_values) || !length(candidate_values) || any(!nzchar(candidate_values))) {
        stop("`decompose_task.candidates` must contain non-empty strings.", call. = FALSE)
      }
    }
  }

  if (method %in% c("ask_human_complete", "ask_human_rule")) {
    if (!is.character(args$node_id) || length(args$node_id) != 1L || !nzchar(args$node_id)) {
      stop("`", method, "` requires a non-empty `node_id` string.", call. = FALSE)
    }
  }

  if (identical(method, "ask_human_changes")) {
    if (length(args)) {
      stop("`ask_human_changes` does not accept arguments.", call. = FALSE)
    }
  }

  if (identical(method, "apply_human_feedback")) {
    if (!is.null(args$completeness) && !is.list(args$completeness)) {
      stop("`apply_human_feedback.completeness` must be a named list.", call. = FALSE)
    }
    if (!is.null(args$remove)) {
      remove_values <- unlist(args$remove, use.names = FALSE)
      if (!is.character(remove_values)) {
        stop("`apply_human_feedback.remove` must be character.", call. = FALSE)
      }
    }
    if (!is.null(args$rule_specs) && !is.list(args$rule_specs)) {
      stop("`apply_human_feedback.rule_specs` must be a named list.", call. = FALSE)
    }
    if (!is.null(args$confidence)) {
      if (!is.list(args$confidence)) {
        stop("`apply_human_feedback.confidence` must be a named list.", call. = FALSE)
      }
      confidence_values <- suppressWarnings(as.numeric(unlist(args$confidence, use.names = FALSE)))
      if (any(is.na(confidence_values)) || any(confidence_values < 0) || any(confidence_values > 1)) {
        stop("`apply_human_feedback.confidence` values must be numeric in [0, 1].", call. = FALSE)
      }
    }
    if (!is.null(args$add)) {
      if (!is.list(args$add)) {
        stop("`apply_human_feedback.add` must be a list of node records.", call. = FALSE)
      }
      for (item in args$add) {
        if (!is.list(item) || !is.character(item$label) || length(item$label) != 1L || !nzchar(item$label)) {
          stop("Each added node must include a non-empty `label`.", call. = FALSE)
        }
        if (!is.null(item$confidence)) {
          confidence_value <- suppressWarnings(as.numeric(item$confidence))
          if (length(confidence_value) != 1L || is.na(confidence_value) ||
              confidence_value < 0 || confidence_value > 1) {
            stop("Added node `confidence` must be numeric in [0, 1].", call. = FALSE)
          }
        }
      }
    }
  }

  invisible(args)
}

#' Build an LLM prompt for scaffolding decisions
#'
#' Creates a prompt that describes the scaffolder's available methods, the task
#' context, the current workflow state, and the required machine-readable JSON
#' response format.
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param task Optional task text. Defaults to the scaffolder's current task.
#' @param format Response format requested from the LLM. Currently only `"json"`
#'   is supported.
#'
#' @return Character string prompt.
#' @export
build_scaffolder_prompt <- function(scaffolder, task = NULL, format = "json") {
  stopifnot(inherits(scaffolder, "Scaffolder"))

  format <- match.arg(format, choices = "json")
  task <- task %||% scaffolder$task

  workflow <- scaffolder$workflow_spec()
  workflow_payload <- list(
    task = workflow$task,
    nodes = workflow$nodes,
    edges = workflow$edges,
    metadata = workflow$metadata
  )

  action_schema <- list(
    actions = list(
      list(
        method = "decompose_task",
        args = list(
          candidates = list(
            "Clarify objectives",
            "Identify decision points"
          )
        )
      ),
      list(
        method = "ask_human_rule",
        args = list(node_id = "node_2")
      )
    ),
    notes = "Optional short reasoning note."
  )

  allowed_methods <- paste(scaffolder_action_methods(), collapse = ", ")
  workflow_json <- jsonlite::toJSON(
    workflow_payload,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )
  schema_json <- jsonlite::toJSON(
    action_schema,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )

  paste(
    "You are assisting a scaffolding-oriented agent framework.",
    "Your job is to decide what scaffolding action should happen next.",
    "",
    "Task:",
    if (is.null(task)) "<unspecified>" else task,
    "",
    "Available scaffolder methods:",
    allowed_methods,
    "",
    "Method semantics:",
    "- evaluate_task(task): register or refresh the active task.",
    "- decompose_task(task, candidates): propose workflow nodes for the task.",
    "- ask_human_complete(node_id): ask whether a node is complete.",
    "- ask_human_changes(): ask whether nodes should be added or removed.",
    "- ask_human_rule(node_id): ask for a node-specific rule.",
    "- apply_human_feedback(...): apply structured updates to the workflow.",
    "",
    "Decision policy:",
    "- Prefer decompose_task when the task has not yet been broken into useful workflow nodes.",
    "- Ask the human only when ambiguity, missing rules, or completion checks block progress.",
    "- Do not ask the human for information that can be inferred directly from the task or current workflow.",
    "- Use apply_human_feedback only for structured workflow updates, not for free-form reasoning.",
    "- Never invent methods outside the allowed method list.",
    "",
    "Current workflow state:",
    workflow_json,
    "",
    "Respond with machine-readable JSON only.",
    "Do not include markdown fences or explanatory prose outside JSON.",
    "The JSON must have an `actions` array and may have a `notes` string.",
    "Each action must contain `method` and `args`.",
    "",
    "Expected JSON shape:",
    schema_json,
    sep = "\n"
  )
}

#' Parse an LLM scaffolder message
#'
#' Parses a machine-readable scaffolder message from JSON into an R list.
#'
#' @param text Character string containing JSON.
#'
#' @return Parsed list.
#' @export
parse_scaffolder_message <- function(text) {
  if (!is.character(text) || length(text) != 1L || !nzchar(text)) {
    stop("`text` must be a non-empty JSON string.", call. = FALSE)
  }

  parsed <- tryCatch(
    jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) {
      stop("Could not parse scaffolder message as JSON.", call. = FALSE)
    }
  )

  validate_scaffolder_message(parsed)
}

#' Validate a machine-readable scaffolder message
#'
#' @param x Parsed scaffolder message.
#' @param allowed_methods Character vector of allowed method names.
#'
#' @return The validated message, invisibly.
#' @export
validate_scaffolder_message <- function(
  x,
  allowed_methods = scaffolder_action_methods()
) {
  if (!is.list(x)) {
    stop("Scaffolder message must be a list.", call. = FALSE)
  }

    if (is.null(x$actions) || !is.list(x$actions)) {
    stop("Scaffolder message must contain an `actions` list.", call. = FALSE)
  }

  for (i in seq_along(x$actions)) {
    action <- x$actions[[i]]
    if (!is.list(action)) {
      stop("Each action must be a list.", call. = FALSE)
    }
    if (!is.character(action$method) || length(action$method) != 1L) {
      stop("Each action must contain a single `method` string.", call. = FALSE)
    }
    if (!(action$method %in% allowed_methods)) {
      stop("Unsupported scaffolder method: ", action$method, call. = FALSE)
    }
    if (is.null(action$args)) {
      action$args <- list()
      x$actions[[i]] <- action
    }
    if (!is.list(action$args)) {
      stop("Each action `args` field must be a list.", call. = FALSE)
    }
    .validate_scaffolder_action_args(action$method, action$args)
  }

  invisible(x)
}

#' Apply a machine-readable scaffolder message
#'
#' Parses and dispatches a machine-readable scaffolder message into concrete
#' calls on a [`Scaffolder`] instance.
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param message Parsed message list or JSON string.
#' @param allowed_methods Character vector of allowed method names.
#'
#' @return List of method-call results.
#' @export
apply_scaffolder_message <- function(
  scaffolder,
  message,
  allowed_methods = scaffolder_action_methods()
) {
  stopifnot(inherits(scaffolder, "Scaffolder"))

  if (is.character(message)) {
    message <- parse_scaffolder_message(message)
  }
  validate_scaffolder_message(message, allowed_methods = allowed_methods)

  results <- vector("list", length(message$actions))

  for (i in seq_along(message$actions)) {
    action <- message$actions[[i]]
    method <- action$method
    args <- action$args

    if (!is.function(scaffolder[[method]])) {
      stop("Scaffolder does not implement method: ", method, call. = FALSE)
    }

    results[[i]] <- list(
      method = method,
      args = args,
      result = do.call(scaffolder[[method]], args)
    )
  }

  results
}
