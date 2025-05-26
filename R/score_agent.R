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
