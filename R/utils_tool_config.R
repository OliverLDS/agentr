.set_tool_config <- function(key) {
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
      url = "https://api.groq.com/openai/v1/chat/completions"
    ),

    # Data Sources
    fred = list(
      api_key = Sys.getenv("FRED_API_KEY"),
      url = "https://api.stlouisfed.org/fred/series",
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



