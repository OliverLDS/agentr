#' @keywords internal
.knowledge_graph_proposal_statuses <- function() {
  c("pending", "under_discussion", "approved", "rejected", "superseded")
}

#' @keywords internal
.normalize_knowledge_graph_proposal_status <- function(x) {
  match.arg(as.character(x)[1], choices = .knowledge_graph_proposal_statuses())
}

#' @keywords internal
.as_knowledge_graph_spec_object <- function(x) {
  if (inherits(x, "agentr_knowledge_graph_spec")) {
    validate_knowledge_graph_spec(x)
    return(x)
  }
  if (is.list(x) && all(c("nodes", "edges", "metadata") %in% names(x))) {
    return(.knowledge_graph_spec_from_list(x))
  }
  stop("Expected an `agentr_knowledge_graph_spec` object or list payload.", call. = FALSE)
}

#' Validate a knowledge graph proposal
#'
#' @param x Knowledge graph proposal record or object.
#'
#' @return The validated proposal, invisibly.
#' @export
validate_knowledge_graph_proposal <- function(x) {
  if (inherits(x, "KnowledgeGraphProposal")) {
    x <- x$to_list()
  }
  required <- c(
    "id", "graph", "status", "notes", "history", "metadata",
    "created_at", "updated_at", "approved_at", "rejected_at",
    "superseded_by", "supersedes"
  )
  if (!is.list(x) || !all(required %in% names(x))) {
    stop("Knowledge graph proposal must contain the required proposal fields.", call. = FALSE)
  }
  if (!is.character(x$id) || length(x$id) != 1L || !nzchar(x$id)) {
    stop("Knowledge graph proposal `id` must be a non-empty string.", call. = FALSE)
  }
  .as_knowledge_graph_spec_object(x$graph)
  .normalize_knowledge_graph_proposal_status(x$status)
  if (!is.list(x$history)) {
    stop("Knowledge graph proposal `history` must be a list.", call. = FALSE)
  }
  .validate_metadata_list(x$metadata)
  invisible(x)
}

#' KnowledgeGraphProposal
#'
#' Proposal object for candidate graph knowledge.
#'
#' @field id Proposal identifier.
#' @field graph Proposed `agentr_knowledge_graph_spec`.
#' @field status Proposal status.
#' @field notes Optional notes.
#' @field history Lifecycle history.
#' @field metadata Free-form metadata.
#' @field created_at Creation timestamp.
#' @field updated_at Last update timestamp.
#' @field approved_at Approval timestamp, or `NA`.
#' @field rejected_at Rejection timestamp, or `NA`.
#' @field superseded_by Proposal identifier that superseded this proposal, or `NA`.
#' @field supersedes Proposal identifier superseded by this proposal, or `NA`.
#'
#' @param graph Proposed `agentr_knowledge_graph_spec` or serializable graph list.
#' @param id Proposal identifier.
#' @param status Proposal status.
#' @param notes Optional proposal notes.
#' @param history Lifecycle history entries.
#' @param metadata Free-form metadata.
#' @param created_at Creation timestamp.
#' @param updated_at Last update timestamp.
#' @param approved_at Approval timestamp, or `NA`.
#' @param rejected_at Rejection timestamp, or `NA`.
#' @param superseded_by Proposal identifier that superseded this proposal, or `NA`.
#' @param supersedes Proposal identifier superseded by this proposal, or `NA`.
#' @param note Discussion or transition note.
#' @param source Discussion source.
#' @param confidence Optional confidence label.
#' @param timestamp Event timestamp.
#' @param ... Unused.
#' @export
KnowledgeGraphProposal <- R6::R6Class(
  classname = "KnowledgeGraphProposal",
  public = list(
    id = NULL,
    graph = NULL,
    status = NULL,
    notes = NULL,
    history = NULL,
    metadata = NULL,
    created_at = NULL,
    updated_at = NULL,
    approved_at = NULL,
    rejected_at = NULL,
    superseded_by = NULL,
    supersedes = NULL,

    #' @description
    #' Create a knowledge graph proposal.
    initialize = function(
      graph,
      id = paste0("knowledge_graph_proposal_", format(Sys.time(), "%Y%m%d%H%M%S")),
      status = "pending",
      notes = NULL,
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
      self$graph <- .as_knowledge_graph_spec_object(graph)
      self$status <- .normalize_knowledge_graph_proposal_status(status)
      self$notes <- if (is.null(notes)) NA_character_ else as.character(notes)[1]
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
      validate_knowledge_graph_proposal(self)
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
    #' Apply a lifecycle transition.
    transition = function(status, note = NULL, timestamp = Sys.time()) {
      status <- .normalize_knowledge_graph_proposal_status(status)
      allowed <- list(
        pending = c("under_discussion", "approved", "rejected", "superseded"),
        under_discussion = c("approved", "rejected", "superseded"),
        approved = character(),
        rejected = character(),
        superseded = character()
      )
      if (!identical(self$status, status) && !(status %in% allowed[[self$status]])) {
        stop("Invalid knowledge graph proposal transition.", call. = FALSE)
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
        graph = self$graph,
        status = self$status,
        notes = self$notes,
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
      cat("<KnowledgeGraphProposal>\n")
      cat("Id:", self$id, "\n")
      cat("Status:", self$status, "\n")
      cat("Nodes:", nrow(self$graph$nodes), "\n")
      cat("Edges:", nrow(self$graph$edges), "\n")
      invisible(self)
    }
  )
)

#' @keywords internal
.as_knowledge_graph_proposal_object <- function(x) {
  if (inherits(x, "KnowledgeGraphProposal")) {
    x$validate()
    return(x)
  }
  if (!is.list(x)) {
    stop("Knowledge graph proposals must be proposal records or `KnowledgeGraphProposal` objects.", call. = FALSE)
  }
  KnowledgeGraphProposal$new(
    id = x$id,
    graph = x$graph,
    status = x$status,
    notes = x$notes,
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

#' KnowledgeGraphProposalState
#'
#' State container for approved graph knowledge plus candidate proposals.
#'
#' @field approved_graph Approved `agentr_knowledge_graph_spec`.
#' @field proposals Named list of [`KnowledgeGraphProposal`] objects.
#' @field history Proposal-state history.
#'
#' @param approved_graph Approved `agentr_knowledge_graph_spec` or serializable graph list.
#' @param proposals Initial proposals.
#' @param history Proposal-state history.
#' @param proposal [`KnowledgeGraphProposal`] object or serializable proposal record.
#' @param proposal_id Proposal identifier.
#' @param status Optional status filter.
#' @param note Discussion or transition note.
#' @param source Discussion source.
#' @export
KnowledgeGraphProposalState <- R6::R6Class(
  classname = "KnowledgeGraphProposalState",
  public = list(
    approved_graph = NULL,
    proposals = NULL,
    history = NULL,

    #' @description
    #' Create a knowledge graph proposal state container.
    initialize = function(approved_graph = new_knowledge_graph_spec(), proposals = list(), history = list()) {
      self$approved_graph <- .as_knowledge_graph_spec_object(approved_graph)
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
      validate_knowledge_graph_spec(self$approved_graph)
      if (!is.list(self$proposals)) {
        stop("`proposals` must be a list.", call. = FALSE)
      }
      for (proposal in self$proposals) {
        proposal$validate()
      }
      invisible(self)
    },

    #' @description
    #' Add a proposal.
    add_proposal = function(proposal) {
      proposal <- .as_knowledge_graph_proposal_object(proposal)
      self$proposals[[proposal$id]] <- proposal
      invisible(proposal)
    },

    #' @description
    #' Return one proposal.
    get_proposal = function(proposal_id) {
      proposal <- self$proposals[[as.character(proposal_id)[1]]]
      if (is.null(proposal)) {
        stop("Unknown knowledge graph proposal: ", proposal_id, call. = FALSE)
      }
      proposal
    },

    #' @description
    #' List proposals with optional status filtering.
    list_proposals = function(status = NULL) {
      proposals <- unname(self$proposals)
      if (!is.null(status)) {
        status <- .normalize_knowledge_graph_proposal_status(status)
        proposals <- Filter(function(proposal) identical(proposal$status, status), proposals)
      }
      proposals
    },

    #' @description
    #' Discuss one proposal.
    discuss_proposal = function(proposal_id, note, source = "human") {
      proposal <- self$get_proposal(proposal_id)
      proposal$discuss(note = note, source = source)
      self$proposals[[proposal$id]] <- proposal
      invisible(proposal)
    },

    #' @description
    #' Approve one proposal and replace the approved graph.
    approve_proposal = function(proposal_id, note = NULL) {
      proposal <- self$get_proposal(proposal_id)
      proposal$approve(note = note)
      self$approved_graph <- proposal$graph
      self$proposals[[proposal$id]] <- proposal
      for (other_id in setdiff(names(self$proposals), proposal$id)) {
        other <- self$proposals[[other_id]]
        if (other$status %in% c("pending", "under_discussion")) {
          other$transition("superseded", note = paste("Superseded by", proposal$id))
          other$superseded_by <- proposal$id
          self$proposals[[other_id]] <- other
        }
      }
      self$history <- c(self$history, list(list(event = "approve", proposal_id = proposal$id, timestamp = Sys.time())))
      invisible(proposal)
    },

    #' @description
    #' Reject one proposal.
    reject_proposal = function(proposal_id, note = NULL) {
      proposal <- self$get_proposal(proposal_id)
      proposal$reject(note = note)
      self$proposals[[proposal$id]] <- proposal
      invisible(proposal)
    },

    #' @description
    #' Return the approved graph.
    approved_spec = function() {
      self$approved_graph
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      list(
        approved_graph = self$approved_graph,
        proposals = lapply(self$proposals, function(proposal) proposal$to_list()),
        history = self$history
      )
    }
  )
)
