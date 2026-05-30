# Knowledge Message Schemas

Narrative knowledge and graph knowledge use separate constrained JSON action
contracts. Applying a message updates proposal state; promotion into active
knowledge remains an explicit approval boundary.

## Narrative Knowledge

Use:

- `knowledge_action_methods()`
- `build_knowledge_elicitation_prompt()`
- `build_knowledge_normalization_prompt()`
- `build_knowledge_conflict_check_prompt()`
- `build_knowledge_design_prompt()`
- `parse_knowledge_message()`
- `preview_knowledge_message()`
- `apply_knowledge_message()`

Knowledge items retain raw and normalized statements, scope, conditions,
exceptions, provenance, review status, and conflict reports when relevant.

## Graph Knowledge

Use:

- `knowledge_graph_action_methods()`
- `build_knowledge_graph_extraction_prompt()`
- `build_knowledge_graph_revision_prompt()`
- `parse_knowledge_graph_message()`
- `preview_knowledge_graph_message()`
- `apply_knowledge_graph_message()`

Graph messages propose nodes and typed edges as first-class knowledge. Unknown
methods and arbitrary code-like actions are rejected.
