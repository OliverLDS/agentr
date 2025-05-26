#' @title Sort agents by score
#' @param agent_registry Named list of agents.
#' @param score_fn Function to score each agent (defaults to `score_agent()`).
#' @return Ordered list of agents (high score first).
#' @export
rank_agents_by_score <- function(agent_registry, score_fn = score_agent) {
  scores <- purrr::map_dbl(agent_registry, score_fn)
  ordered_names <- names(sort(scores, decreasing = TRUE))
  agent_registry[ordered_names]
}

#' @title Select top-N agents
#' @param agent_registry List of all agents.
#' @param n Number to select.
#' @param score_fn Scoring function.
#' @return Named list of selected agents.
#' @export
select_top_agents <- function(agent_registry, n = 5, score_fn = score_agent) {
  sorted <- rank_agents_by_score(agent_registry, score_fn)
  head(sorted, n)
}
