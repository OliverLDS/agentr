# agentr

`agentr` is an R package for specifying, reviewing, and scaffolding agentic AI
systems. It standardizes task-local specs for workflows, memory, knowledge,
interfaces, proposals, and review artifacts so a coding assistant can inspect a
project, infer or revise specs, render review HTML, and implement code against
approved designs.

`agentr` is not a provider-specific LLM client, communication backend,
domain-specific agent, or full execution engine. It supplies the spec shapes,
renderers, validators, prompt contracts, and guidance that make agentic systems
reviewable and portable across downstream runtimes.

## Recommended Workflow

The recommended end-to-end path is coding-assistant scaffolding:

```text
existing task code and docs
-> coding assistant reads agentr guidance
-> assistant infers task-local YAML specs
-> agentr renders review HTML and graph views
-> human reviews specs, diagrams, and outputs
-> assistant revises specs or implementation
-> Git records the evolution
```

Humans generally should not need to write the implementation code by hand. The
R functions remain important because the shipped guidance asks coding assistants
to consume package helpers, conform to standardized spec shapes, validate
artifacts, and render review pages. Function examples are still documented so
humans can inspect what the assistant is using and debug the workflow when
needed.

Start with:

- [Coding Assistant Scaffolding](docs/coding_assistant_scaffolding.md)
- [Full-Stack Task Spec Inference Guide](inst/guides/full_stack_task_spec_inference.md)
- [Workflow-Only Task Spec Inference Guide](inst/guides/workflow_only_task_spec_inference.md)
- [WorkflowSpec Inference Guide](inst/guides/spec_inference/workflow_spec.md)
- [MemorySpec Inference Guide](inst/guides/spec_inference/memory_spec.md)
- [KnowledgeSpec Inference Guide](inst/guides/spec_inference/knowledge_spec.md)
- [KnowledgeGraphSpec Inference Guide](inst/guides/spec_inference/knowledge_graph_spec.md)
- [Task Code Construction Guide](inst/guides/code_construction/task_code_construction.md)
- [Node Script Construction Guide](inst/guides/code_construction/node_script_construction.md)

## What agentr Standardizes

`agentr` organizes agentic designs around reviewable specs:

- `WorkflowSpec`: procedural structure, nodes, edges, gates, branches, schemas, nested workflows, and implementation hints.
- `MemorySpec`: context, semantic, episodic, and procedural memory schema.
- `KnowledgeSpec`: narrative knowledge, rules, heuristics, exceptions, and first-class graph knowledge.
- `AgentSpec`: approved higher-level design bundle.
- `DesignReviewSpec`: browser-review data bundle with workflow, memory, knowledge, proposals, and feedback schema.
- Proposal states: explicit review loops for workflow, agent, memory, narrative knowledge, and graph knowledge.
- Optional node labels: diagnostic color/ontology labels for understanding workflow nodes.

The current built-in node-label ontology uses `RWM`, `PG`, `AE`, `LA`, and
`IAC`, following the five-module vocabulary from [Lamo Castrillo et al.
(2025)][castrillo2025]. These labels are not required for runtime
execution. They are diagnostic annotations for graph coloring, human review,
and capability discussion. Future labeling ontologies can coexist with the same
workflow specs.

[castrillo2025]: https://arxiv.org/abs/2510.09244v1

## Spec Formats

Use the format that matches the boundary:

- YAML is the preferred human-editable source in task folders.
- JSON is for LLM responses, browser feedback, and machine interchange.
- RDS/R6 is for R-native helper objects, proposal state, validation, and cache artifacts.

Typical task-local layout:

```text
tasks/<task_id>/docs/
  workflow_spec.yaml
  memory_spec.yaml
  knowledge_spec.yaml
  knowledge_graph_spec.yaml
  review.html
  inference_notes.md
```

See [Spec Formats](docs/spec_formats.md).

## Rendering And Review

`agentr` can render:

- workflow graphs with `render_workflow_graphviz()`
- memory-schema graphs with `render_memory_schema_graphviz()`
- schema-shape graphs with `render_schema_shape_graphviz()`
- knowledge graphs with `render_knowledge_graphviz()`
- integrated task review pages with `export_design_review_html()`, `render_task_preview()`, and `render_task_previews()`

See [Design Review Layer](docs/design_review_layer.md),
[Workflow Spec](docs/workflow_spec.md), [MemorySpec](docs/memory_spec.md), and
[Knowledge Graph Spec](docs/knowledge_graph_spec.md).

## Documentation

The documentation hub is [docs/index.md](docs/index.md).

Key pages:

- [Architecture](docs/agent_architecture.md)
- [Workflow Spec](docs/workflow_spec.md)
- [MemorySpec](docs/memory_spec.md)
- [KnowledgeSpec Lifecycle](docs/knowledge_spec_lifecycle.md)
- [Knowledge Graph Spec](docs/knowledge_graph_spec.md)
- [Proposal Lifecycle](docs/proposal_lifecycle.md)
- [Workspace CLI Lifecycle](docs/workspace_cli_lifecycle.md)
- [R Function Examples](docs/r_function_examples.md)
- [Function Index](docs/function_index.md)

## Installation

```r
remotes::install_github("OliverLDS/agentr")
```

## Minimal R Inspection Example

The full workflow is usually driven by a coding assistant and task-local specs,
but R helpers are useful for inspection:

```r
library(agentr)

specs <- load_task_specs("tasks/write_new_blog_article")
validate_task_specs("tasks/write_new_blog_article", require = "workflow")

render_task_preview(
  "tasks/write_new_blog_article",
  output_path = "tasks/write_new_blog_article/docs/review.html"
)
```

For more snippets, see [R Function Examples](docs/r_function_examples.md).
