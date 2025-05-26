#' @title Enter a new FSM state
#' @description Updates memory$state and logs the transition.
#' @param memory Agent memory list.
#' @param new_state FSM state string (e.g., "idle", "fetching").
#' @param message Optional annotation.
#' @return Updated memory list.
#' @export
enter_state <- function(memory, new_state, message = NULL) {
  old_state <- memory$state %||% "undefined"
  memory$state <- new_state
  log_fsm_transition(memory$agent_name %||% "unknown", old_state, new_state, message)
  memory
}

#' @title Log FSM transition
#' @description Appends a transition log entry to disk.
#' @param agent_name Name of the agent.
#' @param from From state.
#' @param to To state.
#' @param message Optional message.
#' @export
log_fsm_transition <- function(agent_name, from, to, message = NULL) {
  path <- file.path("logs/fsm", paste0(agent_name, "_fsm_log.json"))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)

  new_entry <- list(
    ts = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    from = from,
    to = to,
    note = message
  )

  if (file.exists(path)) {
    history <- jsonlite::read_json(path, simplifyVector = TRUE)
  } else {
    history <- list()
  }

  history[[length(history) + 1]] <- new_entry
  jsonlite::write_json(history, path, pretty = TRUE, auto_unbox = TRUE)
}
