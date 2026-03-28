library(agentr)

agent <- AgentCore$new(
  id = "demo-agent",
  name = "Demo Scaffold Agent"
)

scaffolder <- Scaffolder$new(agent = agent)
scaffolder$evaluate_task("Draft an implementation-ready workflow for a package refactor.")
scaffolder$decompose_task()

spec <- scaffolder$workflow_spec()
print(spec)
