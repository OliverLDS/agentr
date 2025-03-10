library(httr2)

call_llm <- function(memory, config) {
  messages <- get_recent_messages(memory, 5)
  prompt <- paste(sapply(messages, function(msg) paste0(msg$role, ": ", msg$content)), collapse = "\n")

  response_text <- switch(config$provider,
    "gemini" = call_gemini(prompt, config),
    "openai" = call_openai(prompt, config),
    "claude" = call_claude(prompt, config),
    stop("Unsupported LLM provider: ", config$provider)
  )

  new_memory <- add_message(memory, "assistant", response_text)
  list(memory = new_memory, output = response_text)
}

call_gemini <- function(prompt, config) {
  payload <- list(contents = list(list(parts = list(list(text = prompt)))))
  response <- request(paste0(config$base_url, config$model, ":generateContent")) %>%
    req_url_query(key = config$api_key) %>%
    req_body_json(payload) %>%
    req_perform() %>%
    resp_body_json()
  response$candidates[[1]]$content$parts[[1]]$text
}

call_openai <- function(prompt, config) {
  payload <- list(
    model = config$model,
    messages = list(list(role = "user", content = prompt)),
    max_tokens = 200
  )
  response <- request(paste0(config$base_url, "chat/completions")) %>%
    req_headers("Authorization" = paste("Bearer", config$api_key)) %>%
    req_body_json(payload) %>%
    req_perform() %>%
    resp_body_json()
  response$choices[[1]]$message$content
}

call_claude <- function(prompt, config) {
  payload <- list(
    model = config$model,
    prompt = prompt,
    max_tokens = 200
  )
  response <- request(paste0(config$base_url, "messages")) %>%
    req_headers(
      "x-api-key" = config$api_key,
      "content-type" = "application/json"
    ) %>%
    req_body_json(payload) %>%
    req_perform() %>%
    resp_body_json()
  response$content
}
