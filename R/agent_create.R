#' @title Create a new agent object
#' @description Constructs a logical agent with name, pipeline, and belief memory.
#' @param name Agent name (must be unique).
#' @param pipeline Character vector of policy function names.
#' @param memory Named list representing the agent’s internal belief state.
#' @return An object of class "xagent".
#' @export
create_agent <- function(name, pipeline, memory = list()) {
  structure(
    list(
      name = name,
      pipeline = pipeline,
      memory = memory
    ),
    class = "xagent"
  )
}

#' @title Print an agent
#' @export
print.xagent <- function(x, ...) {
  cat("🤖 Agent:", x$name, "\n")
  cat("⛓️  Pipeline:", paste(x$pipeline, collapse = " → "), "\n")
  cat("🧠 State:", x$memory$state %||% "undefined", "\n")
  invisible(x)
}

#' @title Score agent priority
#' @description Returns a numeric score to help orchestrator allocate compute.
#' @param agent An xagent object.
#' @return Numeric priority score (higher = more urgent/important).
#' @export
score_agent <- function(agent) {
  mem <- agent$memory

  # Example logic; replace with agent-type-specific scoring
  priority <- mem$gap_score %||% 0
  urgency <- mem$urgency %||% 0
  effort <- mem$recent_effort %||% 0

  score <- priority * 2 + urgency - 0.1 * effort
  score
}

