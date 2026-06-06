# agentr Documentation

`agentr` is a scaffolding, specification, and review package for agentic AI
systems. The recommended end-to-end path is coding-assistant scaffolding:
the assistant inspects existing code, infers task-local specs, renders review
artifacts, and implements code against approved designs. `agentr` supplies the
standardized spec shapes, validators, renderers, and guidance for that loop. It
is not a runtime execution engine.

## Start Here

- [Architecture](agent_architecture.md)
- [Workflow Spec](workflow_spec.md)
- [MemorySpec](memory_spec.md)
- [KnowledgeSpec Lifecycle](knowledge_spec_lifecycle.md)
- [Graph Representations](graph_representations.md)
- [Spec Formats](spec_formats.md)
- [R Function Examples](r_function_examples.md)

## Review And Lifecycle

- [Design Review Layer](design_review_layer.md)
- [Proposal Lifecycle](proposal_lifecycle.md)
- [Workflow Scaffolder Message Schema](scaffolder_message_schema.md)
- [Memory Message Schema](memory_message_schema.md)
- [Knowledge Message Schemas](knowledge_message_schema.md)
- [Workspace CLI Lifecycle](workspace_cli_lifecycle.md)
- [Coding Assistant Scaffolding](coding_assistant_scaffolding.md)

## Advanced Concepts

- [Task-Family Design](task_family_design.md)
- [Cold vs Hot Runtime](cold_hot_runtime.md)
- [Capability-Autonomy Landscape](capability_autonomy_landscape.md)
- [Function Index](function_index.md)

## Figures And History

- [Conceptual Figures](conceptual_figures.md)
- [Historical Implementation Plans](archive/plans/index.md)

Package-shipped coding-assistant guides live under `inst/guides/`; see
[Coding Assistant Scaffolding](coding_assistant_scaffolding.md) for how those
guides fit with proposal-state scaffolding and Git-backed spec evolution.
