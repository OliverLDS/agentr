# Example template retained outside the core API surface.
# Use this as a starting point for human-authored workflow experiments.

library(agentr)

agent <- AgentCore$new(name = "Companion Template")
scaffolder <- Scaffolder$new(agent = agent)
scaffolder$evaluate_task("Design a workflow for a companion-style agent.")
scaffolder$decompose_task(candidates = c(
  "Clarify interaction goals",
  "Capture user-specific rules",
  "Draft implementation handoff"
))

scaffolder$workflow_spec()
