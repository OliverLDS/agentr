call_llm <- function(prompt, config, ...) {
  if (config$provider == "openai") {
    return(request_openai(prompt, config, ...))
  } else if (config$provider == "gemini") {
    return(
      request_gemini(
        prompt,
        model = config$model,
        api_key = config$api_key,
        ...
      )
    )
  } else {
    stop("Unsupported provider: ", config$provider)
  }
}

run_llm_interaction <- function(input, memory, config, ...) {
  memory <- add_llm_message(memory, "user", input)
  prompt <- format_llm_prompt(memory)
  response <- call_llm(prompt, config, ...)
  memory <- add_llm_message(memory, "assistant", response)
  list(output = response, memory = memory)
}
