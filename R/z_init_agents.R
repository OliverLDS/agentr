# Initializes all built-in agents for the XAgent framework

# Data Collector Agent
data_collector_goal <- list(task = "Fetch daily macro and crypto data")
data_collector_tools <- list(
  okx_ticker = tool_okx_ticker,
  fred_series = tool_fred_series,
  fetch_rss = tool_fetch_rss
)
agent_data_collector <- create_agent(
  name = "DataCollector",
  goal = data_collector_goal,
  memory = create_memory(),
  policy = policy_data_collector,
  tools = data_collector_tools
)

# Data Reviewer Agent
data_reviewer_goal <- list(task = "Review raw data for quality and signals")
data_reviewer_tools <- list()
agent_data_reviewer <- create_agent(
  name = "DataReviewer",
  goal = data_reviewer_goal,
  memory = create_memory(),
  policy = policy_data_reviewer,
  tools = data_reviewer_tools
)

# Insight Seeker Agent
insight_seeker_goal <- list(task = "Generate daily market insights")
insight_seeker_tools <- list(
  llm = function(prompt) tool_llm(prompt, config = get_tool_config("llm"))
)
agent_insight_seeker <- create_agent(
  name = "InsightSeeker",
  goal = insight_seeker_goal,
  memory = create_llm_memory(),
  policy = policy_insight_seeker,
  tools = insight_seeker_tools
)

# Content Generator Agent
content_generator_goal <- list(task = "Turn insights into publishable content")
content_generator_tools <- list()
agent_content_generator <- create_agent(
  name = "ContentGenerator",
  goal = content_generator_goal,
  memory = create_memory(),
  policy = policy_content_generator,
  tools = content_generator_tools
)

# Content Poster Agent
content_poster_goal <- list(task = "Post generated content")
content_poster_tools <- list(
  post_telegram = tool_post_telegram
)
agent_content_poster <- create_agent(
  name = "ContentPoster",
  goal = content_poster_goal,
  memory = create_memory(),
  policy = policy_content_poster,
  tools = content_poster_tools
)

# Order Placer Agent
order_placer_goal <- list(task = "Place crypto trade if signal is strong")
order_placer_tools <- list(
  place_order = tool_okx_place_order
)
agent_order_placer <- create_agent(
  name = "OrderPlacer",
  goal = order_placer_goal,
  memory = create_memory(),
  policy = policy_order_placer,
  tools = order_placer_tools
)

# Status Checker Agent
status_checker_goal <- list(task = "Monitor order status and update")
status_checker_tools <- list(
  check_order_status = tool_okx_check_order_status
)
agent_status_checker <- create_agent(
  name = "StatusChecker",
  goal = status_checker_goal,
  memory = create_memory(),
  policy = policy_status_checker,
  tools = status_checker_tools
)
