# R Function Examples

The recommended end-to-end workflow is to let a coding assistant inspect the
project, infer specs, render review artifacts, and implement code against
approved designs. The R examples here are still useful because they show the
helpers and spec shapes that the assistant should use. They also give humans a
way to inspect, validate, and debug package behavior when needed.

These examples are not a recommendation that humans hand-code every agentic
workflow. They are reference snippets for review and tool use.

## Load And Validate Task-Local Specs

```r
library(agentr)

paths <- task_spec_paths("tasks/write_new_blog_article")
manifest <- discover_task_specs("tasks/write_new_blog_article")
specs <- load_task_specs("tasks/write_new_blog_article")

validation <- validate_task_specs(
  "tasks/write_new_blog_article",
  require = "workflow",
  stop_on_error = TRUE
)
```

Task-local YAML should be the editable source when present. JSON is useful for
machine interchange, and RDS/R6 remains useful for R-native cache or proposal
state. See [Spec Formats](spec_formats.md).

## Render Review HTML

```r
render_task_preview(
  "tasks/write_new_blog_article",
  output_path = "tasks/write_new_blog_article/docs/review.html",
  graph_layout = "process",
  edge_style = "orthogonal"
)

render_task_previews(
  root = ".",
  tasks_dir = "tasks",
  graph_layout = "process",
  edge_style = "orthogonal"
)
```

The review HTML is an offline inspection artifact. It does not execute the
task runtime.

## Render Standalone Graphs

```r
workflow <- load_workflow_spec("tasks/example/docs/workflow_spec.yaml")
workflow_svg <- render_workflow_graphviz(workflow, as = "svg")

memory <- load_memory_spec("tasks/example/docs/memory_spec.yaml")
memory_svg <- render_memory_schema_graphviz(memory, as = "svg")

schema_svg <- render_schema_shape_graphviz(
  workflow$nodes$output_schema[[1]],
  root_label = "Node output schema",
  as = "svg"
)

knowledge <- load_knowledge_spec("tasks/example/docs/knowledge_spec.yaml")
kg <- knowledge_graph_from_spec(knowledge)
knowledge_svg <- render_knowledge_graphviz(kg, as = "svg")
```

Use graph-shaped knowledge when relationships are part of the design, rather
than merely a projection from narrative knowledge:

```r
knowledge <- KnowledgeSpec$new(
  graph = list(
    nodes = list(
      list(id = "act_r", label = "ACT-R", node_type = "concept", memory_type = "semantic"),
      list(id = "cognitive_architecture", label = "cognitive architecture", node_type = "concept", memory_type = "semantic")
    ),
    edges = list(
      list(from = "act_r", to = "cognitive_architecture", relation = "is_a")
    ),
    metadata = list(source = "coding_assistant_inference")
  )
)

render_knowledge_graphviz(knowledge, as = "svg")
```

## Proposal-State Loop

Proposal objects are useful when Git is not the right version boundary or when
model output must be reviewed before touching approved specs.

```r
workspace <- "my_agent_design"
init_agentr_workspace(workspace)

build_initial_spec_prompt(
  workspace,
  target = "workflow",
  comment = "Design a workflow for reading a paper and extracting schema fields."
)

apply_initial_spec_message(
  workspace,
  target = "workflow",
  message = file.path(workspace, "responses", "workflow_initial.json")
)

list_workspace_proposals(workspace, type = "workflow")
approve_workspace_proposal(
  workspace,
  type = "workflow",
  proposal_id = "proposal_1"
)
```

See [Proposal Lifecycle](proposal_lifecycle.md) and
[Workspace CLI Lifecycle](workspace_cli_lifecycle.md).

## Implementation Handoff Prompt

Implementation prompts are handoff artifacts for a coding assistant or
implementation team. They do not execute the design.

```r
prompt <- build_implementation_prompt(
  workflow,
  language = "R",
  format = "markdown",
  target_agent = "coding_assistant",
  runtime = "zsh orchestrator plus R node scripts",
  constraints = c("Keep node outputs JSON", "Expose -h/--help for scripts")
)

writeLines(prompt, "implementation_prompt.md")
```

For repository-based implementation, prefer giving the coding assistant the
task folder, approved specs, review HTML, and package-shipped guidance under
`inst/guides/`.
