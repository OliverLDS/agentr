df <- tail(agent$load_candles('ETH-USDT-SWAP', '4H'), 300)
df_calculated <- calculate_technical_indicators(df, if_calculate_pivote_zone = FALSE, if_calculate_arima = FALSE)

state <- list(
  long_size = 0,
  avg_long_price = 0,
  short_size = 0,
  avg_short_price = 0,
  wallet_balance = 1000
)

for (i in 51:300) {
  public_row <- df_calculated[i,]
  public_row$latest_close <- public_row$close
  
  pars <- list(
    position_pct = 0.1,
    leverage = 10
  )
  
  print(breakout_v1(state, public_row, pars))
}