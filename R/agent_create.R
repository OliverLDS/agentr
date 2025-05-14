#' Create a new agent
#' @export
create_agent <- function(name, goal, memory, policy, tools = list()) {
  agent <- list(
    name = name,
    goal = goal,
    memory = memory,
    tools = tools,
    policy = policy
  )
  class(agent) <- "xagent"
  return(agent)
}

#' @export
print.xagent <- function(x, ...) {
  cat("Agent:", x$name, "\nGoal:", x$goal$task, "\n")
}
