#' @keywords internal
.as_workflow_proposal_object <- function(x) {
  if (inherits(x, "WorkflowProposal")) {
    x$validate()
    return(x)
  }

  record <- .proposal_record(x)
  validate_workflow_proposal(record)
  WorkflowProposal$new(
    id = record$id,
    workflow = record$workflow,
    status = record$status,
    source = record$source,
    notes = record$notes,
    discussion_rounds = record$discussion_rounds,
    created_at = record$created_at,
    updated_at = record$updated_at,
    approved_at = record$approved_at,
    superseded_by = record$superseded_by,
    supersedes = record$supersedes,
    rejected_at = record$rejected_at
  )
}

#' WorkflowProposalState
#'
#' Public state container for the approved workflow plus stored workflow
#' proposals.
#'
#' @field approved_workflow Current approved workflow specification.
#' @field proposals Named list of `WorkflowProposal` objects.
#' @param approved_workflow Current approved workflow specification used by
#'   `$initialize()`.
#' @param workflow Approved workflow specification used by
#'   `$set_approved_workflow()`.
#' @param proposals Initial proposal objects used by `$initialize()`.
#' @param proposal Proposal object used by `$add_proposal()`.
#' @param proposal_id Proposal identifier used by `$get_proposal()` and
#'   `$approve_proposal()`.
#' @param status Optional proposal status filter used by `$list_proposals()`.
#' @param timestamp Timestamp used by `$approve_proposal()`.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(approved_workflow = new_workflow_spec(...), proposals = list())`}{Create a workflow proposal state container.}
#'   \item{`$set_approved_workflow(workflow)`}{Replace the approved workflow.}
#'   \item{`$add_proposal(proposal)`}{Store a proposal object.}
#'   \item{`$get_proposal(proposal_id)`}{Return a stored proposal by id.}
#'   \item{`$list_proposals(status = NULL)`}{Return a summary table of proposals.}
#'   \item{`$latest_proposal()`}{Return the latest stored proposal or `NULL`.}
#'   \item{`$active_proposals()`}{Return active proposal objects.}
#'   \item{`$proposal_history()`}{Return proposal history in insertion order.}
#'   \item{`$approve_proposal(proposal_id, timestamp = Sys.time())`}{Approve a proposal, update the approved workflow, and supersede older active proposals.}
#'   \item{`$as_list()`}{Return a serializable state snapshot.}
#' }
#'
#' @export
WorkflowProposalState <- R6::R6Class(
  classname = "WorkflowProposalState",
  public = list(
    approved_workflow = NULL,
    proposals = NULL,

    #' @description
    #' Create a `WorkflowProposalState`.
    initialize = function(
      approved_workflow = new_workflow_spec(
        nodes = .empty_workflow_nodes(),
        edges = .empty_workflow_edges(),
        task = NULL,
        metadata = list(
          evaluation = NULL,
          workflow_review = NULL,
          discussion_rounds = list()
        )
      ),
      proposals = list()
    ) {
      validate_workflow_spec(approved_workflow)
      self$approved_workflow <- approved_workflow
      self$proposals <- list()
      if (length(proposals)) {
        for (proposal in proposals) {
          self$add_proposal(proposal)
        }
      }
    },

    #' @description
    #' Replace the approved workflow.
    set_approved_workflow = function(workflow) {
      validate_workflow_spec(workflow)
      self$approved_workflow <- workflow
      invisible(self)
    },

    #' @description
    #' Store a proposal object.
    add_proposal = function(proposal) {
      proposal <- .as_workflow_proposal_object(proposal)
      self$proposals[[proposal$id]] <- proposal
      invisible(proposal)
    },

    #' @description
    #' Return a stored proposal by id.
    get_proposal = function(proposal_id) {
      proposal <- self$proposals[[proposal_id]]
      if (is.null(proposal)) {
        stop("Unknown workflow proposal: ", proposal_id, call. = FALSE)
      }
      proposal
    },

    #' @description
    #' Return proposal summary rows.
    list_proposals = function(status = NULL) {
      proposals <- self$proposal_history()
      if (!is.null(status)) {
        status <- .normalize_workflow_proposal_status(status)
        proposals <- Filter(function(item) identical(item$status, status), proposals)
      }

      if (!length(proposals)) {
        return(data.frame(
          id = character(),
          status = character(),
          source = character(),
          notes = character(),
          node_count = integer(),
          edge_count = integer(),
          created_at = as.POSIXct(character()),
          updated_at = as.POSIXct(character()),
          approved_at = as.POSIXct(character()),
          superseded_by = character(),
          supersedes = character(),
          stringsAsFactors = FALSE
        ))
      }

      do.call(rbind, lapply(proposals, function(item) item$summary()))
    },

    #' @description
    #' Return the latest proposal or `NULL`.
    latest_proposal = function() {
      proposals <- self$proposal_history()
      if (!length(proposals)) {
        return(NULL)
      }
      proposals[[length(proposals)]]
    },

    #' @description
    #' Return active proposals.
    active_proposals = function() {
      Filter(
        function(item) item$status %in% c("pending", "under_discussion"),
        self$proposal_history()
      )
    },

    #' @description
    #' Return proposal history.
    proposal_history = function() {
      unname(self$proposals)
    },

    #' @description
    #' Approve a stored proposal and supersede older active proposals.
    approve_proposal = function(proposal_id, timestamp = Sys.time()) {
      proposal <- self$get_proposal(proposal_id)
      latest_active <- self$latest_proposal()
      proposal$transition(
        to_status = "approved",
        timestamp = timestamp,
        supersedes = if (is.null(latest_active) || identical(latest_active$id, proposal_id)) {
          NULL
        } else {
          latest_active$id
        }
      )
      self$proposals[[proposal_id]] <- proposal

      for (other_id in names(self$proposals)) {
        if (identical(other_id, proposal_id)) {
          next
        }
        other <- self$proposals[[other_id]]
        if (!(other$status %in% c("pending", "under_discussion"))) {
          next
        }
        other$transition(
          to_status = "superseded",
          timestamp = timestamp,
          superseded_by = proposal_id
        )
        self$proposals[[other_id]] <- other
      }

      self$approved_workflow <- proposal$workflow
      invisible(proposal)
    },

    #' @description
    #' Return a serializable state snapshot.
    as_list = function() {
      list(
        approved_workflow = self$approved_workflow,
        proposals = lapply(self$proposals, function(item) item$as_list())
      )
    }
  )
)
