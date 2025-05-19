#' @title Run agent pipeline
#' @description Applies each policy function to the memory sequentially.
#' @param agent An xagent object.
#' @return The updated agent with new memory.
#' @export
run_pipeline <- function(agent) {
  stopifnot(inherits(agent, "xagent"))
  log_info("🔁 Running pipeline for agent: {agent$name}")

  for (policy_name in agent$pipeline) {
    policy_fn <- get(policy_name, mode = "function", inherits = TRUE)

    tryCatch({
      agent$memory <- policy_fn(agent$memory, external_inputs = NULL)
    }, error = function(e) {
      log_error("❌ Policy '{policy_name}' failed for agent '{agent$name}': {e$message}")
      agent$memory$state <- "error"
      agent$memory$error <- list(policy = policy_name, message = e$message, ts = Sys.time())
      break
    })
  }

  invisible(agent)
}

#' @export
run.xagent <- function(x, ...) {
  run_pipeline(x)
}

#' @title Load agents from schedule and run top-priority ones
#' @param schedule_path Path to YAML file defining agent names and load paths.
#' @param max_agents Number of agents to run per cycle.
#' @return Updated list of agents.
#' @export
run_all_agents <- function(schedule_path = "inst/extdata/agent_schedule.yaml", max_agents = 5) {
  schedule_list <- yaml::read_yaml(schedule_path)$schedule

  all_agents <- list()

  for (entry in schedule_list) {
    if (!isTRUE(entry$run)) next
    if (!file.exists(entry$load_from)) {
      log_warn("⚠️ Memory file missing for agent {entry$name}. Skipping.")
      next
    }

    memory <- readRDS(entry$load_from)
    pipeline <- get_agent_pipeline(entry$name)
    agent <- create_agent(entry$name, pipeline, memory)
    all_agents[[entry$name]] <- agent
  }

  # Score and select top agents
  scored <- purrr::map_dbl(all_agents, score_agent)
  top_names <- names(sort(scored, decreasing = TRUE))[1:min(max_agents, length(scored))]

  for (name in top_names) {
    agent <- run_pipeline(all_agents[[name]])
    save_agent_memory(agent)
    all_agents[[name]] <- agent
  }

  invisible(all_agents)
}

