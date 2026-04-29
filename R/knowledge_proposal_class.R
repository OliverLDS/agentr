#' @keywords internal
.knowledge_proposal_statuses <- function() {
  c("pending", "under_discussion", "approved", "rejected", "superseded")
}

#' @keywords internal
.normalize_knowledge_proposal_status <- function(x) {
  match.arg(as.character(x)[1], choices = .knowledge_proposal_statuses())
}

#' @keywords internal
.knowledge_conflict_severities <- function() {
  c("low", "medium", "high")
}

#' @keywords internal
.normalize_conflict_report <- function(x) {
  if (is.null(x)) {
    return(list())
  }
  if (!is.list(x)) {
    stop("`conflict_report` must be a list.", call. = FALSE)
  }
  if (!is.null(x$severity)) {
    x$severity <- match.arg(as.character(x$severity)[1], choices = .knowledge_conflict_severities())
  }
  x
}

#' Validate a knowledge proposal
#'
#' @param x Knowledge proposal record or object.
#'
#' @return Validated proposal, invisibly.
#' @export
validate_knowledge_proposal <- function(x) {
  if (inherits(x, "KnowledgeProposal")) {
    x <- x$to_list()
  }
  required <- c(
    "id", "item", "status", "notes", "conflict_report", "history",
    "metadata", "created_at", "updated_at", "approved_at", "rejected_at",
    "superseded_by", "supersedes"
  )
  if (!is.list(x) || !all(required %in% names(x))) {
    stop("Knowledge proposal must contain the required proposal fields.", call. = FALSE)
  }
  if (!is.character(x$id) || length(x$id) != 1L || !nzchar(x$id)) {
    stop("Knowledge proposal `id` must be a non-empty string.", call. = FALSE)
  }
  validate_knowledge_item(x$item)
  .normalize_knowledge_proposal_status(x$status)
  if (!is.list(x$history)) {
    stop("Knowledge proposal `history` must be a list.", call. = FALSE)
  }
  .validate_metadata_list(x$metadata)
  .normalize_conflict_report(x$conflict_report)
  invisible(x)
}

#' KnowledgeProposal
#'
#' Proposal object for one candidate knowledge item.
#'
#' @field id Proposal identifier.
#' @field item Proposed knowledge item.
#' @field status Proposal status.
#' @field notes Optional notes.
#' @field conflict_report Optional conflict report.
#' @field history Lifecycle history.
#' @field metadata Free-form metadata.
#' @export
KnowledgeProposal <- R6::R6Class(
  classname = "KnowledgeProposal",
  public = list(
    id = NULL,
    item = NULL,
    status = NULL,
    notes = NULL,
    conflict_report = NULL,
    history = NULL,
    metadata = NULL,
    created_at = NULL,
    updated_at = NULL,
    approved_at = NULL,
    rejected_at = NULL,
    superseded_by = NULL,
    supersedes = NULL,

    #' @description
    #' Create a knowledge proposal.
    initialize = function(
      item,
      id = if (is.list(item) && !is.null(item$id)) paste0("knowledge_proposal_", as.character(item$id)[1]) else "knowledge_proposal_1",
      status = "pending",
      notes = NULL,
      conflict_report = list(),
      history = list(),
      metadata = list(),
      created_at = Sys.time(),
      updated_at = created_at,
      approved_at = as.POSIXct(NA),
      rejected_at = as.POSIXct(NA),
      superseded_by = NA_character_,
      supersedes = NA_character_
    ) {
      self$id <- as.character(id)[1]
      self$item <- .coerce_knowledge_item(item)
      self$status <- .normalize_knowledge_proposal_status(status)
      self$notes <- if (is.null(notes)) NA_character_ else as.character(notes)[1]
      self$conflict_report <- .normalize_conflict_report(conflict_report)
      self$history <- history
      self$metadata <- metadata
      self$created_at <- as.POSIXct(created_at)[1]
      self$updated_at <- as.POSIXct(updated_at)[1]
      self$approved_at <- .proposal_time_or_na(approved_at)
      self$rejected_at <- .proposal_time_or_na(rejected_at)
      self$superseded_by <- if (is.null(superseded_by)) NA_character_ else as.character(superseded_by)[1]
      self$supersedes <- if (is.null(supersedes)) NA_character_ else as.character(supersedes)[1]
      self$validate()
    },

    #' @description
    #' Validate the proposal.
    validate = function() {
      validate_knowledge_proposal(self)
      invisible(self)
    },

    #' @description
    #' Append a discussion note.
    discuss = function(note, source = "human", confidence = NA_character_, timestamp = Sys.time()) {
      if (!is.character(note) || length(note) != 1L || !nzchar(note)) {
        stop("`note` must be a non-empty string.", call. = FALSE)
      }
      self$history <- c(self$history, list(list(
        event = "discussion",
        note = note,
        source = as.character(source)[1],
        confidence = if (is.null(confidence)) NA_character_ else as.character(confidence)[1],
        timestamp = as.POSIXct(timestamp)[1]
      )))
      if (identical(self$status, "pending")) {
        self$status <- "under_discussion"
      }
      self$updated_at <- as.POSIXct(timestamp)[1]
      invisible(self)
    },

    #' @description
    #' Apply a status transition.
    transition = function(status, note = NULL, timestamp = Sys.time()) {
      status <- .normalize_knowledge_proposal_status(status)
      allowed <- list(
        pending = c("under_discussion", "approved", "rejected", "superseded"),
        under_discussion = c("approved", "rejected", "superseded"),
        approved = character(),
        rejected = character(),
        superseded = character()
      )
      if (!identical(self$status, status) && !(status %in% allowed[[self$status]])) {
        stop("Invalid knowledge proposal transition.", call. = FALSE)
      }
      self$status <- status
      self$updated_at <- as.POSIXct(timestamp)[1]
      if (identical(status, "approved")) {
        self$approved_at <- self$updated_at
      }
      if (identical(status, "rejected")) {
        self$rejected_at <- self$updated_at
      }
      self$history <- c(self$history, list(list(
        event = "transition",
        status = status,
        note = note,
        timestamp = self$updated_at
      )))
      invisible(self)
    },

    #' @description
    #' Approve the proposal.
    approve = function(note = NULL) {
      self$transition("approved", note = note)
    },

    #' @description
    #' Reject the proposal.
    reject = function(note = NULL) {
      self$transition("rejected", note = note)
    },

    #' @description
    #' Return a serializable representation.
    to_list = function() {
      list(
        id = self$id,
        item = self$item,
        status = self$status,
        notes = self$notes,
        conflict_report = self$conflict_report,
        history = self$history,
        metadata = self$metadata,
        created_at = self$created_at,
        updated_at = self$updated_at,
        approved_at = self$approved_at,
        rejected_at = self$rejected_at,
        superseded_by = self$superseded_by,
        supersedes = self$supersedes
      )
    },

    #' @description
    #' Print a compact summary.
    print = function(...) {
      cat("<KnowledgeProposal>\n")
      cat("Id:", self$id, "\n")
      cat("Status:", self$status, "\n")
      cat("Item:", self$item$id, "\n")
      invisible(self)
    }
  )
)

