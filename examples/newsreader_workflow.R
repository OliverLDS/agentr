# examples/newsreader_workflow.R
# Demonstration of NewsReaderAgent fetching macroeconomic time series

library(XAgent)

# 1. Define Zelina's financial analyst persona
name <- "Zelina"
mind_state <- list(
  identity = "a no-nonsense crypto trader and former investment banker from Hong Kong.",
  personality = "clear, smart, and slightly provocative.",
  tone_guideline = "Use technical vocabulary when needed, but be practical. Prioritize clarity over fluff."
)

# 2. Instantiate the NewsReaderAgent
agent <- NewsReaderAgent$new(name, mind_state)

# 3. Set timezone and FRED config
agent$mind_state$timezone <- "Asia/Hong_Kong"
agent$set_config("fred")   # Ensure tool_set_config("fred") provides a valid FRED API key

# 4. Fetch FRED time series (e.g., U.S. GDP)
df <- agent$fetch_fred_series("GDP")
head(df)
