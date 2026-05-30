# Memory Message Schema

Memory-schema prompts and handlers use constrained JSON actions. They create or
revise `MemoryProposalState`; they do not silently replace an approved
`MemorySpec`.

## Helpers

- `memory_action_methods()`
- `build_memory_schema_prompt()`
- `build_memory_revision_prompt()`
- `parse_memory_message()`
- `preview_memory_message()`
- `apply_memory_message()`

## Boundary

Messages may propose, discuss, approve, reject, or request human clarification
for memory-schema changes only through the methods returned by
`memory_action_methods()`. Unknown methods and arbitrary R code are rejected.

Use YAML for the approved editable memory spec, JSON for model responses, and
RDS for proposal-state persistence where R object fidelity is useful.
