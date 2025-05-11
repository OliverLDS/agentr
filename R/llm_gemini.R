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
    contents = list(
      list(
        role = "user",
        parts = list(
          list(text = prompt)
        )
      )
    ),
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
