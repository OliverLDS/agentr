# Knowledge Message Schema

Knowledge uses a constrained JSON action contract. Applying a message updates
proposal state; promotion into active knowledge remains an explicit approval
boundary. Graph-shaped knowledge should be represented inside `KnowledgeSpec`
instead of through a separate graph proposal state.

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
