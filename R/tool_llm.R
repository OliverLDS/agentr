#' Tool wrapper for LLMs (Gemini, OpenAI, etc.)
#' @export
tool_llm <- function(prompt, config = NULL, ...) {
  if (is.null(config)) stop("LLM config must be provided.")

  provider <- config$provider
  model <- config$model
  api_key <- config$api_key
  temperature <- config$temperature %||% 0.7  # fallback

  if (provider == "gemini") {
    return(request_gemini(
      prompt,
      model = model,
      api_key = api_key,
      temperature = temperature,
      ...
    ))
  } else if (provider == "openai") {
    return(request_openai(  # not implemented here, but placeholder
      prompt,
      model = model,
      api_key = api_key,
      temperature = temperature,
      ...
    ))
  } else {
    stop("Unsupported LLM provider: ", provider)
  }
}

#' Call Gemini API (v1beta) to generate content
#' @export
request_gemini <- function(prompt,
                           model = "gemini-2.0-flash",
                           api_key = Sys.getenv("GEMINI_API_KEY"),
                           temperature = 0.7,
                           top_p = 1,
                           top_k = 40,
                           max_tokens = NULL) {
  if (nchar(api_key) == 0) stop("Missing Gemini API key")

  url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/",
                model, ":generateContent?key=", api_key)

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
  parsed$candidates[[1]]$content$parts[[1]]$text
}

#' Call OpenAI Chat API (v1) to generate content
#' @export
request_openai <- function(prompt,
                           model = "gpt-4-turbo",
                           api_key = Sys.getenv("OPENAI_API_KEY"),
                           temperature = 0.7,
                           max_tokens = 512,
                           system_instruction = NULL,
                           ...) {
  if (nchar(api_key) == 0) stop("Missing OpenAI API key")

  url <- "https://api.openai.com/v1/chat/completions"

  # Build message list
  messages <- list()
  if (!is.null(system_instruction)) {
    messages <- c(messages, list(list(role = "system", content = system_instruction)))
  }
  messages <- c(messages, list(list(role = "user", content = prompt)))

  body <- list(
    model = model,
    messages = messages,
    temperature = temperature,
    max_tokens = max_tokens
  )

  response <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )

  if (httr::status_code(response) != 200) {
    stop("OpenAI API request failed: ", httr::content(response, as = "text"))
  }

  parsed <- httr::content(response, as = "parsed", type = "application/json")
  parsed$choices[[1]]$message$content
}

#' @title Format prompt for LLM summary
#' @description Wraps text with clear instruction separators.
#' @param context The text to summarize.
#' @param mode Output format (e.g., "json", "text").
#' @return Formatted prompt string.
#' @export
format_summary_prompt <- function(context, mode = "json") {
  prompt <- paste0(
    "### Instruction\nSummarize the following article in ", mode, " format:\n\n",
    "### Context\n", context, "\n\n",
    "### Response"
  )
  return(prompt)
}

#' @title Log LLM interaction
#' @description Appends LLM prompt & output to memory.
#' @param memory The memory list.
#' @param prompt Input prompt.
#' @param response Output string.
#' @return Updated memory.
#' @export
log_llm_prompt <- function(memory, prompt, response) {
  memory$llm_log <- c(memory$llm_log %||% list(), list(list(
    ts = Sys.time(),
    prompt = prompt,
    response = response
  )))
  memory
}


