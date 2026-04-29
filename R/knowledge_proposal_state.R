#' @keywords internal
.as_knowledge_proposal_object <- function(x) {
  if (inherits(x, "KnowledgeProposal")) {
    x$validate()
    return(x)
  }
  if (!is.list(x)) {
    stop("Knowledge proposals must be proposal records or `KnowledgeProposal` objects.", call. = FALSE)
  }
  KnowledgeProposal$new(
    id = x$id,
    item = x$item,
    status = x$status,
    notes = x$notes,
    conflict_report = x$conflict_report,
    history = x$history,
    metadata = x$metadata,
    created_at = x$created_at,
    updated_at = x$updated_at,
    approved_at = x$approved_at,
    rejected_at = x$rejected_at,
    superseded_by = x$superseded_by,
    supersedes = x$supersedes
  )
}

#' KnowledgeProposalState
#'
#' State container for approved knowledge plus active and historical proposals.
#'
#' @field approved_knowledge_spec Approved [`KnowledgeSpec`].
#' @field proposals Named list of [`KnowledgeProposal`] objects.
#' @field history Proposal-state history.
#' @export
KnowledgeProposalState <- R6::R6Class(
  classname = "KnowledgeProposalState",
  public = list(
    approved_knowledge_spec = NULL,
    proposals = NULL,
    history = NULL,

    #' @description
    #' Create a knowledge proposal state container.
    initialize = function(
      approved_knowledge_spec = KnowledgeSpec$new(),
      proposals = list(),
      history = list()
    ) {
      self$approved_knowledge_spec <- approved_knowledge_spec
      self$proposals <- list()
      self$history <- history
      for (proposal in proposals) {
        self$add_proposal(proposal)
      }
      self$validate()
    },

    #' @description
    #' Validate the state object.
    validate = function() {
      validate_knowledge_spec(self$approved_knowledge_spec)
      if (!is.list(self$proposals)) {
        stop("`proposals` must be a list.", call. = FALSE)
      }
      for (proposal in self$proposals) {
        proposal$validate()
      }
      invisible(self)
    },

    #' @description
    #' Add a proposal object.
    add_proposal = function(proposal) {
      proposal <- .as_knowledge_proposal_object(proposal)
      self$proposals[[proposal$id]] <- proposal
      invisible(proposal)
    },

    #' @description
    #' Return one stored proposal.
    get_proposal = function(proposal_id) {
      proposal <- self$proposals[[as.character(proposal_id)[1]]]
      if (is.null(proposal)) {
        stop("Unknown knowledge proposal: ", proposal_id, call. = FALSE)
      }
      proposal
    },

    #' @description
    #' List proposals with optional status filtering.
    list_proposals = function(status = NULL) {
      proposals <- unname(self$proposals)
      if (!is.null(status)) {
        status <- .normalize_knowledge_proposal_status(status)
        proposals <- Filter(function(item) identical(item$status, status), proposals)
      }
      proposals
    },

    #' @description
    #' Append a discussion note to one proposal.
    discuss_proposal = function(proposal_id, note, source = "human") {
      proposal <- self$get_proposal(proposal_id)
      proposal$discuss(note = note, source = source)
      self$proposals[[proposal_id]] <- proposal
      invisible(proposal)
    },

    #' @description
    #' Approve one proposal and add its item to approved knowledge.
    approve_proposal = function(proposal_id, note = NULL) {
      proposal <- self$get_proposal(proposal_id)
      proposal$approve(note = note)
      item_id <- proposal$item$id
      if (!is.null(self$approved_knowledge_spec$items[[item_id]])) {
        existing <- self$approved_knowledge_spec$items[[item_id]]
        existing$review$status <- "superseded"
        self$approved_knowledge_spec$items[[item_id]] <- existing
        proposal$supersedes <- item_id
      }
      item <- proposal$item
      item$review$status <- "approved"
      if (is.null(item$normalized_statement) || is.na(item$normalized_statement) || !nzchar(item$normalized_statement)) {
        stop("Approved knowledge items require a normalized statement.", call. = FALSE)
      }
      if (!is.null(self$approved_knowledge_spec$items[[item$id]])) {
        self$approved_knowledge_spec$items[[item$id]] <- item
      } else {
        self$approved_knowledge_spec$add_item(item)
      }
      self$proposals[[proposal_id]] <- proposal
      self$history <- c(self$history, list(list(
        event = "approve",
        proposal_id = proposal_id,
        item_id = item$id,
        timestamp = Sys.time()
      )))
      invisible(proposal)
    },

    #' @description
    #' Reject one proposal.
    reject_proposal = function(proposal_id, note = NULL) {
      proposal <- self$get_proposal(proposal_id)
      proposal$reject(note = note)
      self$proposals[[proposal_id]] <- proposal
      invisible(proposal)
    },

    #' @description
    #' Return the approved knowledge specification.
    approved_spec = function() {
      self$approved_knowledge_spec
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      list(
        approved_knowledge_spec = self$approved_knowledge_spec$to_list(),
        proposals = lapply(self$proposals, function(item) item$to_list()),
        history = self$history
      )
    }
  )
)

#' Save a knowledge specification
#'
#' @param x A [`KnowledgeSpec`] object.
#' @param path File path.
#'
#' @return Invisibly returns `TRUE`.
#' @export
save_knowledge_spec <- function(x, path) {
  validate_knowledge_spec(x)
  .safe_save_rds(x, path)
  invisible(TRUE)
}

#' Load a knowledge specification
#'
#' @param path File path.
#'
#' @return A [`KnowledgeSpec`] object.
#' @export
load_knowledge_spec <- function(path) {
  if (!file.exists(path)) {
    stop("File does not exist: ", path, call. = FALSE)
  }
  x <- .safe_read_rds(path)
  validate_knowledge_spec(x)
  x
}

#' Save a knowledge proposal
#'
#' @param x A [`KnowledgeProposal`] object.
#' @param path File path.
#'
#' @return Invisibly returns `TRUE`.
#' @export
save_knowledge_proposal <- function(x, path) {
  x <- .as_knowledge_proposal_object(x)
  x$validate()
  .safe_save_rds(x, path)
  invisible(TRUE)
}

#' Load a knowledge proposal
#'
#' @param path File path.
#'
#' @return A [`KnowledgeProposal`] object.
#' @export
load_knowledge_proposal <- function(path) {
  if (!file.exists(path)) {
    stop("File does not exist: ", path, call. = FALSE)
  }
  x <- .safe_read_rds(path)
  x <- .as_knowledge_proposal_object(x)
  x$validate()
  x
}

