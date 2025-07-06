#' Save an XAgent object to a file
#'
#' This function saves an XAgent object to a specified `.rds` file.
#'
#' @param agent An object of class \code{XAgent}.
#' @param file_path A string specifying the file path where the agent should be saved.
#'
#' @return No return value. The function is called for its side effect.
#' @export
save_agent <- function(agent, file_path) {
  if (!inherits(agent, "XAgent")) stop("Object is not of class 'XAgent'")
  saveRDS(agent, file = file_path)
  message(paste("Agent saved to", file_path))
}

#' Load an XAgent object from a file
#'
#' This function loads an XAgent object from a saved `.rds` file.
#'
#' @param file_path A string specifying the file path from which to load the agent.
#'
#' @return An object of class \code{XAgent}.
#' @export
load_agent <- function(file_path) {
  if (!file.exists(file_path)) stop("File does not exist:", file_path)
  agent <- readRDS(file_path)
  if (!inherits(agent, "XAgent")) stop("Loaded object is not of class 'XAgent'")
  message(paste("Agent loaded from", file_path))
  return(agent)
}

#' Backup an XAgent object with timestamped filename
#'
#' This function saves a timestamped backup of the agent to a specified directory.
#'
#' @param agent An object of class \code{XAgent}.
#' @param dir A string specifying the backup directory. Defaults to \code{"agent_backups"}.
#'
#' @return No return value. The function is called for its side effect.
#' @export
backup_agent <- function(agent, dir = "agent_backups") {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  file_path <- file.path(dir, paste0(agent$name, "_", timestamp, ".rds"))
  save_agent(agent, file_path)
}

