library(agentr)

agent <- AgentCore$new(
  id = "demo-agent",
  name = "Demo Scaffold Agent"
)

scaffolder <- Scaffolder$new(agent = agent)
scaffolder$evaluate_task("Draft an implementation-ready workflow for a package refactor.")
prompt_json <- build_scaffolder_prompt(scaffolder, format = "json")
prompt_markdown <- build_scaffolder_prompt(scaffolder, format = "markdown")

cat(prompt_markdown)

response_json <- '{
  "actions": [
    {
      "method": "decompose_task",
      "args": {
        "candidates": [
          "Clarify requirements",
          "Capture human rules",
          "Draft implementation handoff"
        ]
      }
    }
  ]
}'

dispatch <- apply_scaffolder_message(scaffolder, response_json)

spec <- scaffolder$workflow_spec()
graph_data <- workflow_graph_data(spec)
questions <- collect_scaffolder_questions(scaffolder, dispatch)

print(spec)
print(graph_data)
print(questions)
