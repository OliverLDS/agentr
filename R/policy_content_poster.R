#' Posts summary to Telegram or web
#' @export
policy_content_poster <- function(input, memory, goal, tools) {
  if (is.null(input)) input <- memory$report
  if (!is.null(tools$post_telegram)) {
    tools$post_telegram(goal$bot_token, goal$chat_id, input)
  }
  memory <- update_memory(memory, "last_posted", Sys.time())
  list(output = "Posted successfully", memory = memory)
}
