#' Places a mock order based on goal or signal
#' @export
policy_order_placer <- function(input, memory, goal, tools) {
  response <- tools$place_order(inst_id = "ETH-USDT", side = "buy", sz = 0.01, px = 1800)
  memory <- update_memory(memory, "last_order", response)
  list(output = response, memory = memory)
}
