# Example template retained outside the core API surface.
# This is a workflow sketch, not an execution engine.

library(agentr)

agent <- AgentCore$new(name = "Trading Template")
scaffolder <- Scaffolder$new(agent = agent)
scaffolder$evaluate_task("Elicit a trading-research workflow from a human operator.")
scaffolder$decompose_task(candidates = c(
  "Define market question",
  "Capture risk rules",
  "Specify review checkpoints",
  "Draft implementation handoff"
))

scaffolder$workflow_spec()
