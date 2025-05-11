LlmConfig <- function(api_key = "", provider = "openai", model = NULL) {
  if (is.null(model)) {
    model <- switch(provider,
                    openai = "gpt-4-turbo",
                    gemini = "gemini-2.0-flash",
                    stop("Unknown provider"))
  }
  list(api_key = api_key, provider = provider, model = model)
}
