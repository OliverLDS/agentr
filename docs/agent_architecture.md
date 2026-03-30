# agentr 0.1.6 Architecture

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

- persistent task evaluation artifacts
- free-form human/model discussion rounds
- candidate node decomposition and non-linear graph suggestions
- workflow-level review
- node-level review
- first-class node and edge editing
- iterative workflow refinement

### LLM bridge layer

Implemented through scaffolder-message helpers that let an external LLM:

- inspect current task and workflow state through `build_scaffolder_prompt()`
- respond with machine-readable JSON actions
- have those actions validated against allowed scaffolder methods and current workflow references
- translate validated actions into concrete `Scaffolder` method calls
- return a normalized dispatch result for downstream orchestration

The bridge is intentionally constrained: it exposes scaffolding methods, not arbitrary code execution.

The dispatch result contains:

- `applied_actions`
- `workflow_after`
- `human_prompts`
- `errors`

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
- `review_status`
- `review_notes`
- `review_confidence`

Workflow specs can also be:

- saved and loaded independently
- exported as graph-ready tables for packages such as `igraph`

## Package Boundaries

`agentr` intentionally excludes:

- raw LLM provider clients
- email, Telegram, and X backends
- domain-specific trading/data agents
- autonomous execution engines

These concerns should live in adjacent packages such as `inferencer` and `dispatchr`.
