LlmConfig <- function(api_key, provider = "gemini", model = NULL, base_url = NULL) {
  if (is.null(base_url)) {
    base_url <- switch(provider,
      "gemini" = "https://generativelanguage.googleapis.com/v1beta/models/",
      "openai" = "https://api.openai.com/v1/",
      "claude" = "https://api.anthropic.com/v1/",
      stop("Unsupported LLM provider: ", provider)
    )
  }

  if (is.null(model)) {
    model <- switch(provider,
      "gemini" = "gemini-2.0-flash",
      "openai" = "gpt-4-turbo",
      "claude" = "claude-3",
      stop("Unsupported LLM provider: ", provider)
    )
  }

  list(api_key = api_key, provider = provider, model = model, base_url = base_url)
}
