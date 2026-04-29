#' Build a knowledge elicitation prompt
#'
#' @param context Optional context text.
#' @param format Output format, `"markdown"` or `"json"`.
#'
#' @return Prompt string.
#' @export
build_knowledge_elicitation_prompt <- function(context = NULL, format = c("markdown", "json")) {
  format <- match.arg(format)
  payload <- list(
    role = "knowledge_elicitor",
    context = context,
    instructions = c(
      "Elicit tacit domain knowledge, rules, exceptions, and evaluation criteria.",
      "Capture raw human statements without pretending they are already normalized.",
      "Return constrained JSON actions only."
    )
  )
  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }
  paste(
    "# Knowledge Elicitation Prompt",
    "",
    "Elicit domain knowledge that should later be normalized and reviewed.",
    if (is.null(context)) "" else paste("Context:", context),
    "",
    "- Capture raw statements, scope conditions, and exceptions.",
    "- Return constrained JSON actions only.",
    sep = "\n"
  )
}

#' Build a knowledge normalization prompt
#'
#' @param raw_statement Raw human knowledge statement.
#' @param format Output format, `"markdown"` or `"json"`.
#'
#' @return Prompt string.
#' @export
build_knowledge_normalization_prompt <- function(raw_statement, format = c("markdown", "json")) {
  format <- match.arg(format)
  schema <- list(
    type = "heuristic",
    domain = "macro_analysis",
    raw_statement = raw_statement,
    normalized_statement = "Normalized knowledge statement.",
    conditions = list("Scope condition"),
    exceptions = list("Exception"),
    confidence = "medium"
  )
  payload <- list(
    role = "knowledge_normalizer",
    raw_statement = raw_statement,
    instructions = c(
      "Convert the raw statement into structured knowledge.",
      "Preserve scope conditions and exceptions.",
      "Do not overclaim certainty."
    ),
    response_requirements = list(
      format = "json",
      schema = schema
    )
  )
  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }
  paste(
    "# Knowledge Normalization Prompt",
    "",
    raw_statement,
    "",
    "Return JSON with type, domain, raw_statement, normalized_statement, conditions, exceptions, and confidence.",
    sep = "\n"
  )
}

#' Build a knowledge conflict-check prompt
#'
#' @param knowledge_spec Existing [`KnowledgeSpec`] or `NULL`.
#' @param candidate Proposed knowledge item.
#' @param format Output format, `"markdown"` or `"json"`.
#'
#' @return Prompt string.
#' @export
build_knowledge_conflict_check_prompt <- function(knowledge_spec = NULL, candidate, format = c("markdown", "json")) {
  format <- match.arg(format)
  existing <- if (is.null(knowledge_spec)) list() else knowledge_spec$to_list()
  schema <- list(
    has_conflict = TRUE,
    conflict_type = "scope_mismatch",
    conflicting_item_ids = list("ki_001"),
    explanation = "Why the candidate conflicts or overlaps.",
    severity = "medium",
    suggested_resolution = "Suggested resolution."
  )
  payload <- list(
    role = "knowledge_conflict_checker",
    existing_knowledge = existing,
    candidate = candidate,
    instructions = c(
      "Check duplication, contradiction, scope mismatch, terminology mismatch, and exception structure.",
      "Return a conflict report even when no conflict exists."
    ),
    response_requirements = list(format = "json", schema = schema)
  )
  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }
  paste("# Knowledge Conflict Check Prompt", "", .prompt_json(payload), sep = "\n")
}

#' Build a knowledge design prompt
#'
#' @param knowledge_state A [`KnowledgeProposalState`] object.
#' @param format Output format, `"markdown"` or `"json"`.
#'
#' @return Prompt string.
#' @export
build_knowledge_design_prompt <- function(knowledge_state, format = c("markdown", "json")) {
  format <- match.arg(format)
  if (!inherits(knowledge_state, "KnowledgeProposalState")) {
    stop("`knowledge_state` must be a `KnowledgeProposalState`.", call. = FALSE)
  }
  payload <- list(
    role = "knowledge_design_reasoner",
    knowledge_state = knowledge_state$as_list(),
    allowed_actions = knowledge_action_methods(),
    instructions = c(
      "Propose, revise, discuss, approve, reject, or conflict-check knowledge items.",
      "Keep actions constrained and machine-readable."
    )
  )
  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }
  paste("# Knowledge Design Prompt", "", .prompt_json(payload), sep = "\n")
}

#' List LLM-callable knowledge methods
#'
#' @return Character vector of allowed knowledge methods.
#' @export
knowledge_action_methods <- function() {
  c(
    "discuss_knowledge_context",
    "propose_knowledge",
    "revise_knowledge_proposal",
    "discuss_knowledge_proposal",
    "approve_knowledge_proposal",
    "reject_knowledge_proposal",
    "check_knowledge_conflict",
    "ask_human_knowledge",
    "ask_human_exception",
    "ask_human_conflict_resolution"
  )
}

#' Parse a knowledge message
#'
#' @param x JSON string, parsed list, or `.json` file path.
#'
#' @return Parsed knowledge message list.
#' @export
parse_knowledge_message <- function(x) {
  x <- .parse_workflow_json_input(x, label = "Knowledge JSON")
  if (!is.list(x) || !is.list(x$actions)) {
    stop("Knowledge messages must contain an `actions` list.", call. = FALSE)
  }
  allowed <- knowledge_action_methods()
  for (action in x$actions) {
    if (!is.list(action) || !is.character(action$method) || length(action$method) != 1L) {
      stop("Each knowledge action must contain a single `method` string.", call. = FALSE)
    }
    if (!(action$method %in% allowed)) {
      stop("Unsupported knowledge action: ", action$method, call. = FALSE)
    }
    if (grepl("code|eval|system|exec", action$method, ignore.case = TRUE)) {
      stop("Unsafe knowledge action rejected.", call. = FALSE)
    }
  }
  x
}

#' Preview a knowledge message
#'
#' @param state A [`KnowledgeProposalState`] object.
#' @param message Parsed or raw knowledge message.
#'
#' @return Preview list.
#' @export
preview_knowledge_message <- function(state, message) {
  if (!inherits(state, "KnowledgeProposalState")) {
    stop("`state` must be a `KnowledgeProposalState`.", call. = FALSE)
  }
  message <- parse_knowledge_message(message)
  list(
    actions = message$actions,
    proposal_count = length(state$proposals),
    approved_items = length(state$approved_knowledge_spec$items)
  )
}

#' Apply a knowledge message
#'
#' @param state A [`KnowledgeProposalState`] object.
#' @param message Parsed or raw knowledge message.
#'
#' @return Mutated state object.
#' @export
apply_knowledge_message <- function(state, message) {
  if (!inherits(state, "KnowledgeProposalState")) {
    stop("`state` must be a `KnowledgeProposalState`.", call. = FALSE)
  }
  message <- parse_knowledge_message(message)
  for (action in message$actions) {
    args <- if (is.null(action$args)) list() else action$args
    method <- action$method
    if (identical(method, "discuss_knowledge_context")) {
      state$history <- c(state$history, list(list(event = "context_discussion", args = args)))
    } else if (identical(method, "propose_knowledge")) {
      item <- list(
        id = if (is.null(args$id)) paste0("ki_", length(state$proposals) + length(state$approved_knowledge_spec$items) + 1L) else args$id,
        type = args$type,
        raw_statement = args$raw_statement,
        normalized_statement = args$normalized_statement,
        domain = args$domain,
        structure = if (is.null(args$structure)) list() else args$structure,
        conditions = if (is.null(args$conditions)) character() else args$conditions,
        exceptions = if (is.null(args$exceptions)) character() else args$exceptions,
        confidence = args$confidence,
        review = list(status = "pending")
      )
      proposal <- KnowledgeProposal$new(item = item, notes = args$notes)
      state$add_proposal(proposal)
    } else if (identical(method, "revise_knowledge_proposal")) {
      proposal <- state$get_proposal(args$proposal_id)
      item <- proposal$item
      for (nm in intersect(names(args), names(item))) {
        item[[nm]] <- args[[nm]]
      }
      proposal$item <- .coerce_knowledge_item(item)
      proposal$updated_at <- Sys.time()
      state$proposals[[proposal$id]] <- proposal
    } else if (identical(method, "discuss_knowledge_proposal")) {
      state$discuss_proposal(args$proposal_id, note = args$note, source = if (is.null(args$source)) "human" else args$source)
    } else if (identical(method, "approve_knowledge_proposal")) {
      state$approve_proposal(args$proposal_id, note = args$note)
    } else if (identical(method, "reject_knowledge_proposal")) {
      state$reject_proposal(args$proposal_id, note = args$note)
    } else if (identical(method, "check_knowledge_conflict")) {
      state$history <- c(state$history, list(list(event = "conflict_check", args = args)))
    } else if (method %in% c("ask_human_knowledge", "ask_human_exception", "ask_human_conflict_resolution")) {
      state$history <- c(state$history, list(list(event = "human_prompt", method = method, args = args)))
    }
  }
  state
}

