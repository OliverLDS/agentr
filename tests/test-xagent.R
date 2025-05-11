library(testthat)

conf <- LlmConfig(api_key = Sys.getenv("GEMINI_API_KEY"), provider = "gemini")
response <- call_llm("List 5 unicorn startup ideas", conf, temperature = 0.5)
cat(response)



