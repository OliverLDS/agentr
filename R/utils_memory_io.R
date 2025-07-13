#' Export an Agent's Memory State to File
#'
#' Saves the `mind_state` object of a given agent to a file for persistence or later reuse.
#'
#' @param agent An XAgent object whose memory (`mind_state`) is to be exported.
#' @param path A character string specifying the file path where the memory should be saved (as `.rds`).
#'
#' @return No return value. Writes the memory to file as a side effect.
#' @export
export_memory <- function(agent, path) {
  saveRDS(agent$mind_state, path)
}

#' Import a Saved Memory State from File
#'
#' Reads a previously saved memory object from an `.rds` file.
#'
#' @param path A character string specifying the file path to load the memory from.
#'
#' @return A list representing the memory state that can be assigned to `agent$mind_state`.
#' @export
import_memory <- function(path) {
  readRDS(path)  
}
