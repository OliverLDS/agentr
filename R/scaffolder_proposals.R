#' @keywords internal
.workflow_proposal_statuses <- function() {
  c("pending", "under_discussion", "approved", "superseded", "rejected")
}

#' @keywords internal
.normalize_workflow_proposal_status <- function(status) {
  match.arg(status, choices = .workflow_proposal_statuses())
}

#' @keywords internal
.proposal_time_or_na <- function(x) {
  if (length(x) == 0L || is.null(x) || all(is.na(x))) {
    return(as.POSIXct(NA))
  }
  as.POSIXct(x)[1]
}

#' @keywords internal
new_workflow_proposal <- function(
  id,
  workflow,
  status = "pending",
  source = "model",
  notes = NULL,
  discussion_rounds = list(),
  created_at = Sys.time(),
  updated_at = created_at,
  approved_at = as.POSIXct(NA),
  superseded_by = NA_character_,
  supersedes = NA_character_,
  rejected_at = as.POSIXct(NA)
) {
  validate_workflow_spec(workflow)

  proposal <- list(
    id = as.character(id),
    status = .normalize_workflow_proposal_status(status),
    source = .normalize_scaffolder_source(source),
    notes = if (is.null(notes)) NA_character_ else as.character(notes),
    workflow = workflow,
    discussion_rounds = discussion_rounds %||% list(),
    created_at = as.POSIXct(created_at)[1],
    updated_at = as.POSIXct(updated_at)[1],
    approved_at = .proposal_time_or_na(approved_at),
    superseded_by = if (is.null(superseded_by)) NA_character_ else as.character(superseded_by)[1],
    supersedes = if (is.null(supersedes)) NA_character_ else as.character(supersedes)[1],
    rejected_at = .proposal_time_or_na(rejected_at)
  )

  class(proposal) <- c("agentr_workflow_proposal", class(proposal))
  validate_workflow_proposal(proposal)
}

#' Validate a workflow proposal
#'
#' Checks that a workflow proposal has the expected structure, valid lifecycle
#' status, and a valid embedded workflow specification.
#'
#' @param x Workflow proposal object.
#'
#' @return The validated proposal, invisibly.
#' @export
validate_workflow_proposal <- function(x) {
  required_fields <- c(
    "id",
    "status",
    "source",
    "notes",
    "workflow",
    "discussion_rounds",
    "created_at",
    "updated_at",
    "approved_at",
    "superseded_by",
    "supersedes",
    "rejected_at"
  )

  if (!is.list(x) || !all(required_fields %in% names(x))) {
    stop("Workflow proposal must contain the required proposal fields.", call. = FALSE)
  }
  if (!is.character(x$id) || length(x$id) != 1L || !nzchar(x$id)) {
    stop("Workflow proposal `id` must be a non-empty string.", call. = FALSE)
  }
  .normalize_workflow_proposal_status(x$status)
  if (!is.list(x$discussion_rounds)) {
    stop("Workflow proposal `discussion_rounds` must be a list.", call. = FALSE)
  }
  if (!inherits(x$workflow, "agentr_workflow_spec")) {
    stop("Workflow proposal `workflow` must inherit from `agentr_workflow_spec`.", call. = FALSE)
  }
  validate_workflow_spec(x$workflow)
  invisible(x)
}

#' @keywords internal
as_workflow_proposal_summary <- function(x) {
  validate_workflow_proposal(x)
  data.frame(
    id = x$id,
    status = x$status,
    source = x$source,
    notes = x$notes,
    node_count = nrow(x$workflow$nodes),
    edge_count = nrow(x$workflow$edges),
    created_at = x$created_at,
    updated_at = x$updated_at,
    approved_at = x$approved_at,
    superseded_by = x$superseded_by,
    supersedes = x$supersedes,
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
workflow_proposal_can_transition <- function(proposal, to_status) {
  validate_workflow_proposal(proposal)
  to_status <- .normalize_workflow_proposal_status(to_status)
  from_status <- proposal$status

  if (identical(from_status, to_status)) {
    return(TRUE)
  }

  allowed <- list(
    pending = c("under_discussion", "approved", "superseded", "rejected"),
    under_discussion = c("approved", "superseded", "rejected"),
    approved = character(),
    superseded = character(),
    rejected = character()
  )

  to_status %in% allowed[[from_status]]
}

#' @keywords internal
transition_workflow_proposal <- function(
  proposal,
  to_status,
  timestamp = Sys.time(),
  superseded_by = NULL,
  supersedes = NULL
) {
  validate_workflow_proposal(proposal)
  to_status <- .normalize_workflow_proposal_status(to_status)

  if (!workflow_proposal_can_transition(proposal, to_status)) {
    stop(
      "Invalid workflow proposal transition from `",
      proposal$status,
      "` to `",
      to_status,
      "`.",
      call. = FALSE
    )
  }

  timestamp <- as.POSIXct(timestamp)[1]
  proposal$status <- to_status
  proposal$updated_at <- timestamp

  if (identical(to_status, "approved")) {
    proposal$approved_at <- timestamp
    proposal$rejected_at <- as.POSIXct(NA)
  }
  if (identical(to_status, "rejected")) {
    proposal$rejected_at <- timestamp
  }
  if (identical(to_status, "superseded")) {
    proposal$superseded_by <- if (is.null(superseded_by)) NA_character_ else as.character(superseded_by)[1]
  }
  if (!is.null(supersedes)) {
    proposal$supersedes <- as.character(supersedes)[1]
  }

  validate_workflow_proposal(proposal)
}

#' @keywords internal
append_workflow_proposal_discussion <- function(
  proposal,
  feedback,
  source = "human",
  confidence = NA_real_,
  timestamp = Sys.time()
) {
  validate_workflow_proposal(proposal)

  if (!is.character(feedback) || length(feedback) != 1L || !nzchar(feedback)) {
    stop("`feedback` must be a non-empty string.", call. = FALSE)
  }
  if (identical(proposal$status, "approved")) {
    stop(
      "Cannot discuss an approved workflow proposal directly. Create a new proposal instead.",
      call. = FALSE
    )
  }

  round <- list(
    source = .normalize_scaffolder_source(source),
    feedback = feedback,
    confidence = .as_optional_confidence(confidence),
    discussed_at = as.POSIXct(timestamp)[1]
  )

  proposal$discussion_rounds <- c(proposal$discussion_rounds, list(round))
  proposal$updated_at <- round$discussed_at

  if (identical(proposal$status, "pending")) {
    proposal <- transition_workflow_proposal(
      proposal,
      to_status = "under_discussion",
      timestamp = round$discussed_at
    )
  }

  list(proposal = proposal, round = round)
}

#' Save a workflow proposal
#'
#' Saves an `agentr_workflow_proposal` object so it can be reviewed, approved,
#' or visualized in a later session.
#'
#' @param proposal Workflow proposal object.
#' @param file_path File path where the proposal should be saved.
#'
#' @return Invisibly returns `TRUE`.
#' @export
save_workflow_proposal <- function(proposal, file_path) {
  validate_workflow_proposal(proposal)
  .safe_save_rds(proposal, file_path)
  invisible(TRUE)
}

#' Load a workflow proposal
#'
#' Loads a previously saved workflow proposal from an `.rds` file.
#'
#' @param file_path File path from which to load the proposal.
#'
#' @return Workflow proposal object.
#' @export
load_workflow_proposal <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("File does not exist: ", file_path, call. = FALSE)
  }
  proposal <- .safe_read_rds(file_path)
  validate_workflow_proposal(proposal)
}

#' Convert a workflow proposal into graph-ready data
#'
#' Exports graph-ready vertex and edge tables for a stored workflow proposal.
#' This accepts either a workflow proposal object directly or a `Scaffolder`
#' plus a proposal id.
#'
#' @param x A workflow proposal object or a [`Scaffolder`] instance.
#' @param proposal_id Optional proposal id when `x` is a [`Scaffolder`].
#'
#' @return A list with `vertices` and `edges`.
#' @export
workflow_proposal_graph_data <- function(x, proposal_id = NULL) {
  if (inherits(x, "Scaffolder")) {
    if (is.null(proposal_id)) {
      stop("`proposal_id` is required when `x` is a Scaffolder.", call. = FALSE)
    }
    proposal <- x$get_workflow_proposal(proposal_id)
    return(workflow_graph_data(proposal$workflow))
  }

  validate_workflow_proposal(x)
  workflow_graph_data(x$workflow)
}

#' Format a workflow proposal
#'
#' @param x Workflow proposal object.
#' @param ... Unused.
#'
#' @export
print.agentr_workflow_proposal <- function(x, ...) {
  validate_workflow_proposal(x)
  cat("<agentr_workflow_proposal>\n")
  cat("Id:", x$id, "\n")
  cat("Status:", x$status, "\n")
  cat("Source:", x$source, "\n")
  cat("Nodes:", nrow(x$workflow$nodes), "\n")
  cat("Edges:", nrow(x$workflow$edges), "\n")
  invisible(x)
}

#' @keywords internal
active_workflow_proposals <- function(scaffolder) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  Filter(
    function(item) item$status %in% c("pending", "under_discussion"),
    unname(scaffolder$proposal_log)
  )
}

#' @keywords internal
latest_workflow_proposal <- function(scaffolder) {
  proposals <- proposal_history(scaffolder)
  if (!length(proposals)) {
    return(NULL)
  }
  proposals[[length(proposals)]]
}

#' @keywords internal
proposal_history <- function(scaffolder) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  unname(scaffolder$proposal_log)
}
