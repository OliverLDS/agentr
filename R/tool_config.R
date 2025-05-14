#' Create a configuration list for an LLM tool
#' @export
create_llm_config <- function(api_key,
                              provider = "gemini",
                              model = NULL,
                              temperature = 0.7,
                              ...) {
  if (is.null(model)) {
    model <- switch(provider,
                    gemini = "gemini-2.0-flash",
                    openai = "gpt-4-turbo",
                    stop("Unknown provider"))
  }

  list(
    api_key = api_key,
    provider = provider,
    model = model,
    temperature = temperature,
    ...
  )
}


#' Create a configuration list for OKX API
#' @export
create_okx_config <- function(api_key, secret_key, passphrase, subaccount = NULL) {
  list(
    api_key = api_key,
    secret_key = secret_key,
    passphrase = passphrase,
    subaccount = subaccount
  )
}


#' Create a configuration list for FRED API
#' @export
create_fred_config <- function(api_key) {
  list(
    api_key = api_key
  )
}


#' Create a configuration list for Telegram bot
#' @export
create_telegram_config <- function(bot_token, chat_id) {
  list(
    bot_token = bot_token,
    chat_id = chat_id
  )
}

#' Get preconfigured tool config by name (loads from environment variables)
#' @export
get_tool_config <- function(name) {
  switch(tolower(name),
    llm = create_llm_config(api_key = Sys.getenv("GEMINI_API_KEY")),
    okx = create_okx_config(
      api_key = Sys.getenv("OKX_API_KEY"),
      secret_key = Sys.getenv("OKX_SECRET_KEY"),
      passphrase = Sys.getenv("OKX_PASSPHRASE")
    ),
    fred = create_fred_config(api_key = Sys.getenv("FRED_API_KEY")),
    telegram = create_telegram_config(
      bot_token = Sys.getenv("TELEGRAM_BOT_TOKEN"),
      chat_id = Sys.getenv("TELEGRAM_CHAT_ID")
    ),
    stop("Unknown config name: ", name)
  )
}
