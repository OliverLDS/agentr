#' Send a Text Message to Telegram
#'
#' Sends a plain text message to a Telegram chat using the bot API.
#'
#' @param message_text A character string with the message content.
#' @param config A list containing \code{bot_token}, \code{chat_id}, and \code{parse_mode}.
#'
#' @return Invisibly returns the API response (as an \code{httr} object).
#' @export
send_text_TG <- function(message_text, config) {
  bot_token <- config$bot_token
  chat_id <- config$chat_id
  parse_mode <- config$parse_mode
  url <- sprintf("https://api.telegram.org/bot%s/sendMessage", bot_token)
  res <- httr::POST(url,
    body = list(
      chat_id = chat_id,
      text = message_text,
      parse_mode = parse_mode
    ),
    encode = "form"
  )

  if (httr::status_code(res) != 200) {
    warning("Telegram message failed: ", httr::content(res, as = "text"))
  }

  invisible(res)
}

#' Send an Image to Telegram
#'
#' Sends a photo with an optional caption to a Telegram chat.
#'
#' @param image_path File path to the image to be uploaded.
#' @param caption_text Optional caption text for the image.
#' @param config A list containing \code{bot_token}, \code{chat_id}, and \code{parse_mode}.
#'
#' @return Invisibly returns the API response (as an \code{httr} object).
#' @export
send_image_TG <- function(image_path, caption_text = NULL, config) {
  bot_token <- config$bot_token
  chat_id <- config$chat_id
  parse_mode <- config$parse_mode
  if (is.null(caption_text)) parse_mode <- NULL # caption should not contain special chars like _. so it is a guard here
  url <- sprintf("https://api.telegram.org/bot%s/sendPhoto", bot_token)
  res <- httr::POST(url,
    body = list(
      chat_id = chat_id,
      caption = caption_text,
      photo = httr::upload_file(image_path),
      parse_mode = parse_mode
    ),
    encode = "multipart"
  )
  
  if (httr::status_code(res) != 200) {
    warning("Telegram message failed: ", httr::content(res, as = "text"))
  }

  invisible(res)
}

#' Synchronize New Telegram Messages
#'
#' Retrieves Telegram updates via the Bot API and filters for new user messages
#' that match a specified chat ID. Returns only messages not yet seen based on \code{old_update_ids}.
#'
#' @param old_update_ids A character vector of previously seen Telegram \code{update_id}s.
#' @param config A list containing Telegram API credentials: \code{bot_token} and \code{chat_id}.
#'
#' @return A list with:
#' \describe{
#'   \item{\code{new_ids}}{New \code{update_id}s not seen in \code{old_update_ids}.}
#'   \item{\code{df}}{A data frame of new Telegram messages.}
#'   \item{\code{has_new}}{Logical indicating whether new messages were found.}
#' }
#' @export
sync_TG_chats <- function(old_update_ids, config) {
  bot_token <- config$bot_token
  chat_id <- config$chat_id
  url <- sprintf("https://api.telegram.org/bot%s/getUpdates", bot_token)
  
  res <- httr::GET(url)
  updates <- httr::content(res, as = "parsed")$result
  
  if (length(updates) == 0) {
    return(list(new_ids = character(0), df = data.frame(), has_new = FALSE))
  }
  
  rows <- lapply(updates, function(u) {
    if (!is.null(u$message$text) && u$message$chat$id == chat_id) {
      data.frame(
        update_id = u$update_id,
        time      = as.POSIXct(u$message$date, origin = "1970-01-01", tz = "UTC"),
        role      = "user",
        msg       = u$message$text,
        channel   = "TG",
        stringsAsFactors = FALSE
      )
    } else {
      NULL
    }
  })

  new_df <- do.call(rbind, Filter(Negate(is.null), rows))
  
  util_sync_new_records(
    new_df     = new_df,
    key_column = "update_id",
    old_keys   = old_update_ids
  )
}

# this is for chatting (we will have different function, actually same, for posting to a TG channel)
# agent <- XAgent$new(name = 'Xiaowei')
# agent$set_config('tg')
# agent$get_chats()
# agent$sync_TG_chats()
# agent$get_chats()
# 
# agent$send_text_TG('how are you?')
# agent$send_image_TG('~/monthly_return_chart_NEARUSDT_BandFade_1.png', 'NEARUSDT BandFade')
# agent$sync_TG_chats()
# agent$get_chats()




