#' Checks status of most recent order
#' @export
policy_status_checker <- function(input, memory, goal, tools) {
  order <- memory$last_order
  if (is.null(order$order_id)) {
    return(list(output = "No order found.", memory = memory))
  }
  status <- tools$check_order_status(order$instId, order$order_id)
  memory <- update_memory(memory, "last_status", status)
  list(output = status, memory = memory)
}
