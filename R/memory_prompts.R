#' List LLM-callable memory methods
#'
#' @return Character vector of allowed memory methods.
#' @export
memory_action_methods <- function() {
  c(
    "discuss_memory_context",
    "propose_memory_schema",
    "revise_memory_proposal",
    "discuss_memory_proposal",
    "approve_memory_proposal",
    "reject_memory_proposal",
    "ask_human_memory_field",
    "ask_human_memory_persistence",
    "ask_human_memory_update_policy"
  )
}

#' Build a memory schema prompt
#'
#' @param context Optional context text.
#' @param current_memory Optional [`MemorySpec`] or `NULL`.
#' @param format Output format, `"markdown"` or `"json"`.
#'
#' @return Prompt string.
#' @export
build_memory_schema_prompt <- function(context = NULL, current_memory = NULL, format = c("markdown", "json")) {
  format <- match.arg(format)
  memory_payload <- if (is.null(current_memory)) NULL else .as_memory_spec_object(current_memory)$to_list()
  payload <- list(
    role = "memory_schema_designer",
    context = context,
    current_memory = memory_payload,
    memory_types = memory_types(),
    persistence_policies = memory_persistence_policies(),
    allowed_actions = memory_action_methods(),
    instructions = c(
      "Draft or revise an agent memory schema.",
      "Classify fields as context, semantic, episodic, or procedural memory.",
      "Specify persistence and update policy for each field.",
      "Return constrained JSON actions only."
    ),
    response_schema = list(
      actions = list(list(
        method = "propose_memory_schema",
        args = list(
          memory_spec = list(
            fields = list(list(
              id = "current_task_context",
              label = "Current task context",
              memory_type = "context",
              description = "Current task state.",
              schema = list(fields = list("task_id")),
              persistence = "session",
              update_policy = list(updated_by = "scaffolder")
            )),
            metadata = list()
          ),
          notes = "Why this schema is proposed."
        )
      ))
    )
  )
  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }
  paste("# Memory Schema Prompt", "", .prompt_json(payload), sep = "\n")
}

#' Build a memory revision prompt
#'
#' @param memory_state A [`MemoryProposalState`] object.
#' @param feedback Optional human feedback text or structured list.
#' @param format Output format, `"markdown"` or `"json"`.
#'
#' @return Prompt string.
#' @export
build_memory_revision_prompt <- function(memory_state, feedback = NULL, format = c("markdown", "json")) {
  format <- match.arg(format)
  if (!inherits(memory_state, "MemoryProposalState")) {
    stop("`memory_state` must be a `MemoryProposalState`.", call. = FALSE)
  }
  payload <- list(
    role = "memory_schema_reviser",
    memory_state = memory_state$as_list(),
    feedback = feedback,
    allowed_actions = memory_action_methods(),
    instructions = c(
      "Revise memory schema proposals using the human feedback.",
      "Prefer structured proposal revisions over free text.",
      "Return constrained JSON actions only."
    )
  )
  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }
  paste("# Memory Revision Prompt", "", .prompt_json(payload), sep = "\n")
}

#' @keywords internal
.memory_spec_from_message_payload <- function(x) {
  if (inherits(x, "MemorySpec")) {
    return(x)
  }
  if (!is.list(x)) {
    stop("Memory message `memory_spec` must be a list or `MemorySpec`.", call. = FALSE)
  }
  fields <- if (is.null(x$fields)) list() else x$fields
  MemorySpec$new(fields = fields, metadata = if (is.null(x$metadata)) list() else x$metadata)
}

#' Parse a memory message
#'
#' @param x JSON string, parsed list, or `.json` file path.
#'
#' @return Parsed memory message list.
#' @export
parse_memory_message <- function(x) {
  x <- .parse_workflow_json_input(x, label = "Memory JSON")
  if (!is.list(x) || !is.list(x$actions)) {
    stop("Memory messages must contain an `actions` list.", call. = FALSE)
  }
  allowed <- memory_action_methods()
  for (action in x$actions) {
    if (!is.list(action) || !is.character(action$method) || length(action$method) != 1L) {
      stop("Each memory action must contain a single `method` string.", call. = FALSE)
    }
    if (!(action$method %in% allowed)) {
      stop("Unsupported memory action: ", action$method, call. = FALSE)
    }
    if (grepl("code|eval|system|exec", action$method, ignore.case = TRUE)) {
      stop("Unsafe memory action rejected.", call. = FALSE)
    }
  }
  x
}

#' Preview a memory message
#'
#' @param state A [`MemoryProposalState`] object.
#' @param message Parsed or raw memory message.
#'
#' @return Preview list.
#' @export
preview_memory_message <- function(state, message) {
  if (!inherits(state, "MemoryProposalState")) {
    stop("`state` must be a `MemoryProposalState`.", call. = FALSE)
  }
  message <- parse_memory_message(message)
  list(
    actions = message$actions,
    proposal_count = length(state$proposals),
    approved_fields = length(state$approved_memory_spec$fields)
  )
}

#' Apply a memory message
#'
#' @param state A [`MemoryProposalState`] object.
#' @param message Parsed or raw memory message.
#'
#' @return Mutated state object.
#' @export
apply_memory_message <- function(state, message) {
  if (!inherits(state, "MemoryProposalState")) {
    stop("`state` must be a `MemoryProposalState`.", call. = FALSE)
  }
  message <- parse_memory_message(message)
  for (action in message$actions) {
    args <- if (is.null(action$args)) list() else action$args
    method <- action$method
    if (identical(method, "discuss_memory_context")) {
      state$history <- c(state$history, list(list(event = "context_discussion", args = args)))
    } else if (identical(method, "propose_memory_schema")) {
      spec <- .memory_spec_from_message_payload(args$memory_spec)
      proposal <- MemoryProposal$new(
        memory_spec = spec,
        id = if (is.null(args$proposal_id)) paste0("memory_proposal_", length(state$proposals) + 1L) else args$proposal_id,
        notes = args$notes
      )
      state$add_proposal(proposal)
    } else if (identical(method, "revise_memory_proposal")) {
      proposal <- state$get_proposal(args$proposal_id)
      proposal$memory_spec <- .memory_spec_from_message_payload(args$memory_spec)
      proposal$updated_at <- Sys.time()
      state$proposals[[proposal$id]] <- proposal
    } else if (identical(method, "discuss_memory_proposal")) {
      state$discuss_proposal(args$proposal_id, note = args$note, source = if (is.null(args$source)) "human" else args$source)
    } else if (identical(method, "approve_memory_proposal")) {
      state$approve_proposal(args$proposal_id, note = args$note)
    } else if (identical(method, "reject_memory_proposal")) {
      state$reject_proposal(args$proposal_id, note = args$note)
    } else if (method %in% c("ask_human_memory_field", "ask_human_memory_persistence", "ask_human_memory_update_policy")) {
      state$history <- c(state$history, list(list(event = "human_prompt", method = method, args = args)))
    }
  }
  state
}

