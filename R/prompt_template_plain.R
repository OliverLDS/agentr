#' Compose a Plain Prompt for LLM Interaction
#'
#' Constructs a natural language prompt for a language model based on agent metadata
#' and optional chat history. This function is used to build context-aware prompts
#' for querying LLMs like Groq or Gemini.
#'
#' @param name The name of the agent.
#' @param identity A short string describing the agent's identity or role.
#' @param personality A string describing the agent's personality traits.
#' @param tone_guideline Optional. A character string specifying tone guidance for responses (e.g., "friendly", "formal").
#' @param chat_history Optional. A character string representing previous conversation history with the user.
#'
#' @return A character string representing the full prompt to be sent to a language model.
#'
#' @examples
#' compose_prompt_plain(
#'   name = "Xiaowei",
#'   identity = "an AI poet and companion",
#'   personality = "introspective, warm, and imaginative",
#'   tone_guideline = "gentle and thoughtful",
#'   chat_history = "User: How are you?\nXiaowei: I feel a calm breeze today."
#' )
#'
#' @export
compose_prompt_plain <- function(name, identity, personality, tone_guideline = NULL, chat_history = NULL) {
  prompt <- sprintf(
    "You are %s, %s.\nYour personality: %s.",
    name, identity, personality
  )

  if (!is.null(tone_guideline) && nzchar(tone_guideline)) {
    prompt <- paste0(prompt, "\nTone guideline: ", tone_guideline)
  }

  if (!is.null(chat_history) && nzchar(chat_history)) {
    prompt <- paste0(prompt, "\n\nBelow is your previous chatting with the user:\n", chat_history)
  }

  return(prompt)
}