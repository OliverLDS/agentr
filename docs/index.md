# agentr Documentation

`agentr` is a scaffolding, specification, and human-review package for
progressively turning human-owned workflow judgment into inspectable agent
design artifacts. It is not a runtime execution engine.

## Start Here

- [Architecture](agent_architecture.md)
- [Workflow Spec](workflow_spec.md)
- [MemorySpec](memory_spec.md)
- [KnowledgeSpec Lifecycle](knowledge_spec_lifecycle.md)
- [Knowledge Graph Spec](knowledge_graph_spec.md)
- [Spec Formats](spec_formats.md)

## Review And Lifecycle

- [Design Review Layer](design_review_layer.md)
- [Proposal Lifecycle](proposal_lifecycle.md)
- [Workflow Scaffolder Message Schema](scaffolder_message_schema.md)
- [Memory Message Schema](memory_message_schema.md)
- [Knowledge Message Schemas](knowledge_message_schema.md)
- [Workspace CLI Lifecycle](workspace_cli_lifecycle.md)

## Advanced Concepts

- [Task-Family Design](task_family_design.md)
- [Cold vs Hot Runtime](cold_hot_runtime.md)
- [Capability-Autonomy Landscape](capability_autonomy_landscape.md)
- [Function Index](function_index.md)

## Manuscript And History

- [Manuscript Assets](manuscript_assets.md)
- [Conceptual Figures](conceptual_figures.md)
- [Historical Implementation Plans](archive/plans/index.md)

Package-shipped coding-assistant guides live under `inst/guides/`. They explain
how a coding assistant should infer descriptive task specs from existing code
and how approved specs can guide downstream code construction without turning
`agentr` into an executor.
