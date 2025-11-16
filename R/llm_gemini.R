#' Query the Google Gemini API with a Prompt
#'
#' Sends a user-defined prompt to the Gemini language model via Google’s Generative Language API.
#' The model configuration (e.g., temperature, top_p, etc.) is passed via the \code{config} list.
#'
#' This function supports model options such as:
#' - \code{temperature}: Sampling temperature
#' - \code{topP}: Nucleus sampling threshold
#' - \code{topK}: Top-k filtering
#' - \code{max_tokens} (optional): Maximum output tokens
#'
#' @param prompt A character string representing the prompt to send to the model.
#' @param config A named list containing the model parameters and API key:
#' \describe{
#'   \item{\code{api_key}}{Your Gemini API key.}
#'   \item{\code{model}}{Model name, e.g., \code{"gemini-2.5-flash"}.}
#'   \item{\code{temperature}}{Sampling temperature.}
#'   \item{\code{top_p}}{Nucleus sampling threshold.}
#'   \item{\code{top_k}}{Top-k sampling size.}
#'   \item{\code{max_tokens}}{(Optional) Maximum number of tokens to generate.}
#' }
#'
#' @return A character string containing the model's response.
#' @examples
#' config <- tool_set_config("gemini")
#' query_gemini("What is the capital of Japan?", config)
#'
#' @export
query_gemini <- function(prompt, config) {

  api_key <- config$api_key
  model <- config$model
  temperature <- config$temperature
  top_p <- config$top_p
  top_k <- config$top_k
  max_tokens <- config$max_tokens

  url <- sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", model, api_key)
  
  body <- list(
    contents = list(list(
      role = "user",
      parts = list(list(text = prompt))
    )),
    generationConfig = list(
      temperature = temperature,
      topP = top_p,
      topK = top_k
    )
  )

  if (!is.null(max_tokens)) {
    body$generationConfig$maxOutputTokens <- max_tokens
  }

  response <- httr::POST(
    url,
    httr::add_headers(`Content-Type` = "application/json"),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )

  if (httr::status_code(response) != 200) {
    stop("Gemini API request failed: ", httr::content(response, as = "text"))
  }

  parsed <- httr::content(response, as = "parsed", type = "application/json")
  return(parsed$candidates[[1]]$content$parts[[1]]$text)
}
