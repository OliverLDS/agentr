#' Post message to Telegram channel or chat
#' @export
tool_post_telegram <- function(bot_token, chat_id, message) {
  url <- paste0("https://api.telegram.org/bot", bot_token, "/sendMessage")
  httr::POST(url, body = list(chat_id = chat_id, text = message), encode = "form")
}
