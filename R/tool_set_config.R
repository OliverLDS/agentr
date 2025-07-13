#' Retrieve Tool Configuration by Key
#'
#' Returns a predefined configuration list for an external tool or API.
#' This function supports dynamic assignment of API keys and parameters via environment variables.
#'
#' Available keys include:
#' - \code{"gemini"}: Google Gemini LLM config
#' - \code{"groq"}: Groq API config (LLaMA models)
#' - \code{"fred"}: Federal Reserve Economic Data (FRED)
#' - \code{"alphavantage"}: AlphaVantage financial API
#' - \code{"tg"}: Telegram bot configuration
#' - \code{"localchat"}: Local text-based chat (file + editor)
#' - \code{"email"}: SMTP email config
#' - \code{"okx1"}: OKX trading API (first account)
#' - \code{"okx2"}: OKX trading API (second account)
#'
#' @param key A character string (case-insensitive) representing the config type.
#'
#' @return A named list of configuration parameters for the requested tool.
#'
#' @examples
#' tool_set_config("groq")
#' tool_set_config("tg")
#'
#' @export
tool_set_config <- function(key) {
  key <- tolower(key)
  ConfigList <- list(

    # LLMs
    gemini = list(
      api_key = Sys.getenv("GEMINI_API_KEY"),
      model = "gemini-2.5-flash",
      temperature = 0.7,
      top_p = 1,
      top_k = 40,
      max_tokens = NULL
    ),
    groq = list(
      api_key = Sys.getenv("GROQ_API_KEY"),
      url = "https://api.groq.com/openai/v1/chat/completions",
      model = "llama3-70b-8192"
    ),

    # DataSources
    fred = list(
      api_key = Sys.getenv("FRED_API_KEY"),
      url = "https://api.stlouisfed.org/fred/series/observations",
      mode = 'json'
    ),
    alphavantage = list(
      api_key = Sys.getenv("AlphaVantage_API_KEY"),
      url = "https://www.alphavantage.co/query"
    ),

    # Communication
    tg = list(
      bot_token = Sys.getenv("TG_BOT_TOKEN"),
      chat_id = Sys.getenv("TG_CHAT_ID"),
      channel_id = Sys.getenv("TG_CHANNEL_ID"),
      parse_mode = "Markdown"
    ),
    localchat = list(
      chat_file = "/tmp/agent_chats.txt",
      editor = "textmate"
    ),
    email = list(
      from = Sys.getenv("EMAIL_FROM"),
      password = Sys.getenv("EMAIL_APP_PASSWORD")
    ),

    # Trading
    okx = list(
      api_key = Sys.getenv("OKX_API_KEY"),
      secret_key = Sys.getenv("OKX_SECRET_KEY"),
      passphrase = Sys.getenv("OKX_PASSPHRASE")
    )
  )
  return(ConfigList[[key]])
}

# tool_set_config('telegram')
# agent <- XAgent$new()
# agent$set_config('telegram')
# agent$get_config('telegram')
# agent$get_logs()
