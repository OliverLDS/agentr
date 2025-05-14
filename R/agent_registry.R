#' @export
get_agent <- function(name) {
  switch(tolower(name),
    data_collector      = agent_data_collector,
    data_reviewer       = agent_data_reviewer,
    insight_seeker      = agent_insight_seeker,
    content_generator   = agent_content_generator,
    content_poster      = agent_content_poster,
    order_placer        = agent_order_placer,
    status_checker      = agent_status_checker,
    stop("Unknown agent: ", name)
  )
}

