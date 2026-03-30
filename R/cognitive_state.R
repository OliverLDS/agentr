#' CognitiveState
#'
#' Minimal structured cognitive layer for agent state representation.
#' This class intentionally provides only a lightweight API for `0.1.3`.
#' Its `bayes_update()` method is a placeholder interface rather than a full
#' inference engine.
#'
#' @field beliefs Named list of beliefs.
#' @field knowledge List of observations, notes, or external facts.
#' @field goals List of goal records.
#' @field task_context Free-form task context list.
#' @field confidence Named numeric vector of confidence scores.
#' @field update_log List of update events.
#' @param beliefs Named list used by `$initialize()`.
#' @param knowledge List used by `$initialize()` and `$add_knowledge()`.
#' @param goals Goal list used by `$initialize()`.
#' @param task_context Task context list used by `$initialize()`.
#' @param confidence Confidence vector used by `$initialize()` and
#'   `$set_belief()`.
#' @param update_log Update log used by `$initialize()`.
#' @param name Belief name used by `$set_belief()`.
#' @param value Belief or update value used by `$set_belief()` and
#'   `$record_update()`.
#' @param entry Knowledge entry used by `$add_knowledge()`.
#' @param label Optional knowledge label used by `$add_knowledge()`.
#' @param id Goal identifier used by `$set_goal()`.
#' @param description Goal description used by `$set_goal()`.
#' @param status Goal status used by `$set_goal()`.
#' @param ... Named task-context updates used by `$set_context()`.
#' @param target Update target used by `$bayes_update()`.
#' @param evidence Evidence payload used by `$bayes_update()`.
#' @param prior Optional prior payload used by `$bayes_update()`.
#' @param note Optional note used by `$bayes_update()`.
#' @param type Update type used by `$record_update()`.
#' @param key Update key used by `$record_update()`.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(beliefs = list(), knowledge = list(), goals = list(), task_context = list(), confidence = numeric(), update_log = list())`}{Create a lightweight cognitive state container.}
#'   \item{`$set_belief(name, value, confidence = NULL)`}{Store or update a named belief and optional confidence value.}
#'   \item{`$add_knowledge(entry, label = NULL)`}{Append a knowledge record with timestamped provenance.}
#'   \item{`$set_goal(id, description, status = "proposed")`}{Store or update a goal record.}
#'   \item{`$set_context(...)`}{Merge named task-context fields into the current cognitive state.}
#'   \item{`$bayes_update(target, evidence, prior = NULL, note = NULL)`}{Record a placeholder Bayesian-style update artifact.}
#'   \item{`$as_list()`}{Return the cognitive state as a plain list.}
#'   \item{`$record_update(type, key, value, confidence = NULL)`}{Append a structured update record to the update log.}
#' }
#'
#' @export
CognitiveState <- R6::R6Class(
  classname = "CognitiveState",
  public = list(
    beliefs = NULL,
    knowledge = NULL,
    goals = NULL,
    task_context = NULL,
    confidence = NULL,
    update_log = NULL,

    #' @description
    #' Create a `CognitiveState` with beliefs, knowledge, goals, and context.
    initialize = function(
      beliefs = list(),
      knowledge = list(),
      goals = list(),
      task_context = list(),
      confidence = numeric(),
      update_log = list()
    ) {
      self$beliefs <- beliefs
      self$knowledge <- knowledge
      self$goals <- goals
      self$task_context <- task_context
      self$confidence <- confidence
      self$update_log <- update_log
    },

    #' @description
    #' Store or update a named belief and optional confidence value.
    set_belief = function(name, value, confidence = NULL) {
      self$beliefs[[name]] <- value
      if (!is.null(confidence)) {
        self$confidence[[name]] <- confidence
      }
      self$record_update(
        type = "belief",
        key = name,
        value = value,
        confidence = confidence
      )
      invisible(self)
    },

    #' @description
    #' Append a timestamped knowledge record to the cognitive state.
    add_knowledge = function(entry, label = NULL) {
      record <- list(
        label = label,
        entry = entry,
        recorded_at = Sys.time()
      )
      self$knowledge[[length(self$knowledge) + 1]] <- record
      self$record_update(type = "knowledge", key = label, value = entry)
      invisible(self)
    },

    #' @description
    #' Store or update a structured goal record.
    set_goal = function(id, description, status = "proposed") {
      self$goals[[id]] <- list(
        id = id,
        description = description,
        status = status,
        updated_at = Sys.time()
      )
      self$record_update(type = "goal", key = id, value = description)
      invisible(self)
    },

    #' @description
    #' Merge named task-context fields into the current state.
    set_context = function(...) {
      updates <- list(...)
      if (!length(updates)) {
        return(invisible(self))
      }
      for (name in names(updates)) {
        self$task_context[[name]] <- updates[[name]]
      }
      self$record_update(type = "context", key = names(updates), value = updates)
      invisible(self)
    },

    #' @description
    #' Record a placeholder Bayesian-style update artifact.
    bayes_update = function(target, evidence, prior = NULL, note = NULL) {
      update_record <- list(
        target = target,
        evidence = evidence,
        prior = prior,
        note = note,
        updated_at = Sys.time(),
        status = "placeholder"
      )
      self$update_log[[length(self$update_log) + 1]] <- update_record
      invisible(update_record)
    },

    #' @description
    #' Return the cognitive state as a plain list.
    as_list = function() {
      list(
        beliefs = self$beliefs,
        knowledge = self$knowledge,
        goals = self$goals,
        task_context = self$task_context,
        confidence = self$confidence,
        update_log = self$update_log
      )
    },

    #' @description
    #' Append a structured update event to the update log.
    record_update = function(type, key, value, confidence = NULL) {
      self$update_log[[length(self$update_log) + 1]] <- list(
        type = type,
        key = key,
        value = value,
        confidence = confidence,
        updated_at = Sys.time()
      )
      invisible(self)
    }
  )
)
