#' @title Load agents from a schedule YAML
#' @param path Path to YAML file (e.g., agent_schedule.yaml).
#' @return Named list of agent objects.
#' @export
load_agents_from_yaml <- function(path = "inst/extdata/agent_schedule.yaml") {
  schedule <- yaml::read_yaml(path)$schedule
  agent_registry <- list()

  for (entry in schedule) {
    if (!isTRUE(entry$run)) next
    if (!file.exists(entry$load_from)) {
      log_warn("Agent '{entry$name}' memory not found at: {entry$load_from}")
      next
    }

    memory <- readRDS(entry$load_from)
    pipeline <- get_agent_pipeline(entry$name)

    agent_registry[[entry$name]] <- create_agent(entry$name, pipeline, memory)
  }

  agent_registry
}

#' @title Filter agents by FSM state
#' @param registry Named list of agents.
#' @param allowed_states Vector of allowed memory$state values.
#' @return Subset of registry.
#' @export
filter_active_agents <- function(registry, allowed_states = c("ready", "pending", "active")) {
  purrr::keep(registry, function(agent) {
    (agent$memory$state %||% "unknown") %in% allowed_states
  })
}
