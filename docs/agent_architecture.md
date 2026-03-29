# agentr 0.1.3 Architecture

`agentr` is the agent core, not the execution layer.

## Layers

### Cognitive layer

Implemented as `CognitiveState`, a structured and evolving state container for:

- beliefs
- knowledge
- goals
- task context
- confidence
- update history

The `bayes_update()` method is intentionally a placeholder API in `0.1.3`.

### Affective layer

Implemented as `AffectiveState`, which preserves and cleans up the existing emotion code:

- primary affect dimensions
- time-based decay
- inertia-aware updates
- natural-language summaries

### Scaffolding layer

Implemented as `Scaffolder`, which supports:

- task evaluation
- candidate node decomposition
- provisional confidence assignment
- completeness checks
- add/remove node prompts
- node-specific rule capture
- iterative workflow refinement

### LLM bridge layer

Implemented through scaffolder-message helpers that let an external LLM:

- inspect current task and workflow state through `build_scaffolder_prompt()`
- respond with machine-readable JSON actions
- have those actions validated against allowed scaffolder methods
- translate validated actions into concrete `Scaffolder` method calls

The bridge is intentionally constrained: it exposes scaffolding methods, not arbitrary code execution.

## Workflow Output

Workflow objects are outputs of reasoning and scaffolding. They are represented by `agentr_workflow_spec` and contain:

- `nodes`
- `edges`
- `task`
- `metadata`

Node records include:

- `confidence`
- `human_required`
- `rule_spec`
- `implementation_hint`
- `complete`

## Package Boundaries

`agentr` intentionally excludes:

- raw LLM provider clients
- email, Telegram, and X backends
- domain-specific trading/data agents
- autonomous execution engines

These concerns should live in adjacent packages such as `inferencer` and `dispatchr`.
