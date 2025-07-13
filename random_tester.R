# devtools::install_github("OliverLDS/XAgent")
# devtools::install_github("OliverLDS/okxr")
library('XAgent')
library('okxr')

agent_path <- '~/Documents/2025/_2025-06-17_Zelina'
memory_path <- '~/Documents/2025/_2025-06-17_Zelina/memory'

name <- "Zelina"
agent <- CryptoTraderAgent$new(name)
agent$mind_state <- import_memory(sprintf('%s/%s', memory_path, 'zelina_memory_1.rds')) # use other's memory
agent$mind_state$timezone <- "Asia/Hong_Kong"
agent$set_config('okx')
agent$load_okxr()
# agent$mind_state$tool_config$okx <- list(
#   api_key = Sys.getenv("OKX_API_KEY2"), 
#   secret_key = Sys.getenv("OKX_SECRET_KEY2"), 
#   passphrase = Sys.getenv("OKX_PASSPHRASE2")
# )
agent$set_okx_candle_dir('~/Documents/2025/_2025-06-17_Crypto_Data/okx')
agent$set_cdd_bt_dir('~/Documents/2025/_2025-07-11_BackTestingResults/cdd')
save_agent(agent, sprintf('%s/zelina.rds', agent_path))