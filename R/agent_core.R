#' AgentCore
#'
#' Minimal agent container for the `agentr` cognitive core.
#' An `AgentCore` combines cognitive and affective state layers and can
#' optionally own a [`Scaffolder`] instance for human-in-the-loop workflow
#' elicitation.
#'
#' @field id Agent identifier.
#' @field name Human-readable agent name.
#' @field cognition A [`CognitiveState`] instance.
#' @field affect An [`AffectiveState`] instance.
#' @field scaffolder Optional [`Scaffolder`] instance.
#' @field metadata Free-form metadata list.
#' @param id Agent identifier used by `$initialize()`.
#' @param name Human-readable agent name used by `$initialize()`.
#' @param cognition A [`CognitiveState`] instance used by `$initialize()`.
#' @param affect An [`AffectiveState`] instance used by `$initialize()`.
#' @param metadata Free-form metadata list used by `$initialize()`.
#' @param scaffolder Optional [`Scaffolder`] instance used by
#'   `$attach_scaffolder()`.
#'
#' @export
AgentCore <- R6::R6Class(
  classname = "AgentCore",
  public = list(
    id = NULL,
    name = NULL,
    cognition = NULL,
    affect = NULL,
    scaffolder = NULL,
    metadata = NULL,

    initialize = function(
      id = "agentr-core",
      name = "agentr",
      cognition = CognitiveState$new(),
      affect = AffectiveState$new(),
      metadata = list()
    ) {
      stopifnot(inherits(cognition, "CognitiveState"))
      stopifnot(inherits(affect, "AffectiveState"))

      self$id <- id
      self$name <- name
      self$cognition <- cognition
      self$affect <- affect
      self$metadata <- metadata
    },

    attach_scaffolder = function(scaffolder = NULL) {
      if (is.null(scaffolder)) {
        scaffolder <- Scaffolder$new(agent = self)
      }
      stopifnot(inherits(scaffolder, "Scaffolder"))
      self$scaffolder <- scaffolder
      invisible(self)
    },

    snapshot = function() {
      list(
        id = self$id,
        name = self$name,
        cognition = self$cognition$as_list(),
        affect = self$affect$as_list(),
        metadata = self$metadata
      )
    }
  )
)
