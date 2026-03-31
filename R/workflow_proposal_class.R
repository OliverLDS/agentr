#' @keywords internal
.proposal_record <- function(x) {
  if (inherits(x, "WorkflowProposal")) {
    return(x$as_list())
  }
  x
}

#' WorkflowProposal
#'
#' Public workflow proposal object with explicit lifecycle state and persistence
#' helpers.
#'
#' @field id Workflow proposal identifier.
#' @field status Workflow proposal lifecycle status.
#' @field source Proposal source label.
#' @field notes Optional proposal notes.
#' @field workflow Proposed workflow specification.
#' @field discussion_rounds Stored discussion rounds.
#' @field created_at Proposal creation time.
#' @field updated_at Latest proposal update time.
#' @field approved_at Approval time.
#' @field superseded_by Newer proposal id that superseded this proposal.
#' @field supersedes Older proposal id superseded by this proposal.
#' @field rejected_at Rejection time.
#' @param id Workflow proposal identifier.
#' @param workflow Proposed workflow specification.
#' @param status Workflow proposal lifecycle status.
#' @param source Proposal source label.
#' @param notes Optional proposal notes.
#' @param discussion_rounds Stored discussion rounds.
#' @param created_at Proposal creation time.
#' @param updated_at Latest proposal update time.
#' @param approved_at Approval time.
#' @param superseded_by Newer proposal id that superseded this proposal.
#' @param supersedes Older proposal id superseded by this proposal.
#' @param rejected_at Rejection time.
#' @param to_status Target lifecycle status used by `$transition()`.
#' @param timestamp Timestamp used by `$transition()` and `$discuss()`.
#' @param feedback Discussion feedback used by `$discuss()`.
#' @param confidence Optional discussion confidence used by `$discuss()`.
#' @param file_path File path used by `$save()`.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(...)`}{Create a workflow proposal object.}
#'   \item{`$validate()`}{Validate the proposal state and embedded workflow.}
#'   \item{`$as_list()`}{Return the proposal as a serializable proposal record.}
#'   \item{`$summary()`}{Return a one-row summary data frame.}
#'   \item{`$transition(to_status, timestamp = Sys.time(), superseded_by = NULL, supersedes = NULL)`}{Apply a valid lifecycle transition.}
#'   \item{`$discuss(feedback, source = "human", confidence = NA_real_, timestamp = Sys.time())`}{Append a discussion round and transition into discussion state when needed.}
#'   \item{`$graph_data()`}{Export graph-ready data from the proposed workflow.}
#'   \item{`$save(file_path)`}{Save the proposal to disk.}
#' }
#'
#' @export
WorkflowProposal <- R6::R6Class(
  classname = "WorkflowProposal",
  public = list(
    id = NULL,
    status = NULL,
    source = NULL,
    notes = NULL,
    workflow = NULL,
    discussion_rounds = NULL,
    created_at = NULL,
    updated_at = NULL,
    approved_at = NULL,
    superseded_by = NULL,
    supersedes = NULL,
    rejected_at = NULL,

    #' @description
    #' Create a `WorkflowProposal`.
    initialize = function(
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
      self$id <- as.character(id)
      self$status <- .normalize_workflow_proposal_status(status)
      self$source <- .normalize_scaffolder_source(source)
      self$notes <- if (is.null(notes)) NA_character_ else as.character(notes)
      self$workflow <- workflow
      self$discussion_rounds <- discussion_rounds %||% list()
      self$created_at <- as.POSIXct(created_at)[1]
      self$updated_at <- as.POSIXct(updated_at)[1]
      self$approved_at <- .proposal_time_or_na(approved_at)
      self$superseded_by <- if (is.null(superseded_by)) NA_character_ else as.character(superseded_by)[1]
      self$supersedes <- if (is.null(supersedes)) NA_character_ else as.character(supersedes)[1]
      self$rejected_at <- .proposal_time_or_na(rejected_at)
      self$validate()
    },

    #' @description
    #' Validate the proposal.
    validate = function() {
      validate_workflow_proposal(self)
      invisible(self)
    },

    #' @description
    #' Return a serializable proposal record.
    as_list = function() {
      record <- list(
        id = self$id,
        status = self$status,
        source = self$source,
        notes = self$notes,
        workflow = self$workflow,
        discussion_rounds = self$discussion_rounds,
        created_at = self$created_at,
        updated_at = self$updated_at,
        approved_at = self$approved_at,
        superseded_by = self$superseded_by,
        supersedes = self$supersedes,
        rejected_at = self$rejected_at
      )
      class(record) <- c("agentr_workflow_proposal", class(record))
      record
    },

    #' @description
    #' Return a one-row proposal summary.
    summary = function() {
      as_workflow_proposal_summary(self)
    },

    #' @description
    #' Apply a valid lifecycle transition.
    transition = function(
      to_status,
      timestamp = Sys.time(),
      superseded_by = NULL,
      supersedes = NULL
    ) {
      updated <- transition_workflow_proposal(
        self,
        to_status = to_status,
        timestamp = timestamp,
        superseded_by = superseded_by,
        supersedes = supersedes
      )
      private$assign_from_record(updated)
      invisible(self)
    },

    #' @description
    #' Append a discussion round to the proposal.
    discuss = function(
      feedback,
      source = "human",
      confidence = NA_real_,
      timestamp = Sys.time()
    ) {
      out <- append_workflow_proposal_discussion(
        self,
        feedback = feedback,
        source = source,
        confidence = confidence,
        timestamp = timestamp
      )
      private$assign_from_record(out$proposal)
      invisible(self)
    },

    #' @description
    #' Export graph-ready proposal workflow data.
    graph_data = function() {
      workflow_proposal_graph_data(self)
    },

    #' @description
    #' Save the proposal to disk.
    save = function(file_path) {
      save_workflow_proposal(self, file_path)
      invisible(TRUE)
    }
  ),
  private = list(
    assign_from_record = function(record) {
      record <- .proposal_record(record)
      self$id <- record$id
      self$status <- record$status
      self$source <- record$source
      self$notes <- record$notes
      self$workflow <- record$workflow
      self$discussion_rounds <- record$discussion_rounds
      self$created_at <- record$created_at
      self$updated_at <- record$updated_at
      self$approved_at <- record$approved_at
      self$superseded_by <- record$superseded_by
      self$supersedes <- record$supersedes
      self$rejected_at <- record$rejected_at
    }
  )
)

#' @export
print.WorkflowProposal <- function(x, ...) {
  print.agentr_workflow_proposal(x$as_list(), ...)
}
