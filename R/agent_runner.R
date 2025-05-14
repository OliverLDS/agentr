#' Run an agent and return result
#' @export
run_agent <- function(agent, input = NULL) {
  result <- agent$policy(input, agent$memory, agent$goal, agent$tools)
  agent$memory <- result$memory
  return(result)
}

#' Run a list of agents in sequence, passing output as input
#' @export
run_pipeline <- function(agent_list, input = NULL) {
  for (i in seq_along(agent_list)) {
    agent <- agent_list[[i]]
    result <- agent$policy(input, agent$memory, agent$goal, agent$tools)
    agent$memory <- result$memory
    input <- result$output  # pass to next agent
  }
  return(input)
}
