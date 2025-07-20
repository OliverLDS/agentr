#' Initialize Default Mind State for an XAgent
#'
#' This function returns a default `mind_state` list used to configure an \code{XAgent}'s internal state.
#' If an existing partial mind state is provided, it will overwrite the corresponding fields.
#'
#' The mind state includes:
#' - \code{identity}, \code{personality}, \code{tone_guideline}: Character descriptors
#' - \code{knowledge}, \code{beliefs}, \code{values}: Internal mental model
#' - \code{emotion_state}: A structured list describing emotional intensity and mood
#' - \code{goals}: Agent’s current objectives
#' - \code{history}: Logs, chat history, summary, and Telegram chat IDs
#' - \code{current_context}: Contains finite state machine (FSM) state
#' - \code{tool_config}: Configuration list for external tools (LLMs, TG, etc.)
#'
#' @param mind_state A list optionally containing some or all fields to override the defaults.
#'
#' @return A named list representing the complete initial \code{mind_state}.
#' @export
init_mind_state <- function(mind_state = NULL) {
  default_state <- list(
    identity = NA_character_,
    personality = NA_character_,
    tone_guideline = NA_character_,
    knowledge = list(),
    beliefs = list(),
    values = list(risk_aversion = NA_real_, verbosity = NA_real_),
    emotion_state = default_emotion_state(),
    goals = list(),
    history = list(logs = list(), chats = list(), summary = NA_character_, TG_chat_ids = integer(0)),
    current_context = list(state = NA_character_)
  )

  if (!is.null(mind_state)) {
    for (k in names(mind_state)) {
      default_state[[k]] <- mind_state[[k]]
    }
  }

  return(default_state)
}
