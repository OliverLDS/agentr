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
      "method": "discuss_task",
      "args": {
        "feedback": "Approval rules may require a dedicated review node.",
        "source": "model"
      }
    },
    {
      "method": "decompose_task",
      "args": {
        "suggestions": {
          "nodes": [
            {"id": "node_1", "label": "Clarify requirements", "confidence": 0.9},
            {"id": "node_2", "label": "Capture human rules", "confidence": 0.8},
            {"id": "node_3", "label": "Draft implementation handoff", "depends_on": ["node_1", "node_2"], "confidence": 0.7}
          ]
        }
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
