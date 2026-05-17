# agentr 0.2.5.6 Architecture

`agentr` is the agent core, not the execution layer.

For diagram-oriented summaries of the architecture and lifecycle, see [conceptual_figures.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/conceptual_figures.md), [figures/index.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/index.md), and [manuscript_assets.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/manuscript_assets.md).

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
- subsystem recommendation and sparse subsystem selection
- workflow node subsystem ownership labels
- free-form human/model discussion rounds
- candidate node decomposition and non-linear graph suggestions
- workflow-level review
- node-level review
- first-class node and edge editing
- draft and approved agent-spec state
- workflow proposal preview, approval, and supersession
- draft agent-spec proposal creation, discussion, and approval
- iterative workflow refinement

Internally, `0.2.5.6` keeps `Scaffolder` as the facade while separating:

- workflow mutation helpers
- proposal lifecycle helpers
- dispatch helpers
- prompt-contract helpers

Public agent-design objects now include:

- `AgentSpec`
- `SubsystemSpec`
- `AgentScaffoldState`
- `IntelligentAgent`

Public workflow proposal lifecycle objects remain:

- `WorkflowProposal`
- `WorkflowProposalState`

The package now keeps two design axes separate:

- subsystem axis: `RWM`, `PG`, `AE`, `IAC`, `LA`
- workflow axis: DAG nodes and edges

`RWM` is further refined into:

- `CognitiveConfig`
- `AffectiveConfig`

### LLM bridge layer

Implemented through scaffolder-message helpers that let an external LLM:

- inspect current task and workflow state through `build_scaffolder_prompt()`
- inspect agent-design state through `build_agent_design_prompt()`
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

Preview flows can also store proposal records without mutating the live workflow. Proposal lifecycle state is explicit: `pending`, `under_discussion`, `approved`, `superseded`, and `rejected`.

Persisted proposal artifacts and proposal state objects are now part of the supported workflow-review model:

- proposals can be validated independently
- proposals can be saved and loaded outside a live `Scaffolder`
- proposals can be visualized directly as graph-ready data

Agent-design proposals now sit alongside workflow proposals inside the scaffolder design loop:

- workflow proposals preserve candidate workflow structure before approval
- agent-spec proposals preserve candidate agent designs before approval
- linked approval can promote both the workflow and the higher-level agent design together

Memory-schema and graph-knowledge proposals now follow the same proposal lifecycle outside the main `Scaffolder` facade:

- memory proposals preserve candidate `MemorySpec` schemas before approval
- graph proposals preserve candidate `agentr_knowledge_graph_spec` relationships before approval
- constrained message handlers keep model-suggested changes inspectable before they become active specs

## Agent Output

`AgentSpec` is now the top-level design artifact. It contains:

- `task`
- `agent_name`
- `summary`
- `subsystems`
- `workflow`
- `knowledge_spec`
- `memory_spec`
- `state_requirements`
- `state_spec`
- `interfaces`
- `interface_spec`
- `autonomy_spec`
- `autonomy_stage`
- `implementation_targets`
- `metadata`

`KnowledgeSpec` can now contain narrative items, first-class graph knowledge, and future vector-reference metadata. `MemorySpec` is the preferred structured schema for context, semantic, episodic, and procedural memory. `state_spec` remains available for backward-compatible loose-list state descriptions.

`SubsystemSpec` keeps sparse subsystem selection explicit. Subsystem fields may be absent, which preserves the design principle that not all tasks need all subsystems.

## Workflow Output

Workflow objects remain outputs of reasoning and scaffolding. They are represented by `agentr_workflow_spec` and contain:

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
- rendered as Graphviz DOT, DiagrammeR graphs, or SVG for workflow inspection

Within `0.2.5.6`, workflow ownership labels live in workflow metadata so workflow-first compatibility remains intact while agent designs can still mark which subsystem owns each node. Those ownership labels can now be edited incrementally rather than only replaced wholesale.

Within `0.2.5.6`, `DesignReviewSpec` adds a data-contract boundary for future JS/HTML review tools. It packages workflow graph data, memory schema, narrative knowledge, graph knowledge, proposal states, and structured feedback schema without turning `agentr` into a browser UI or execution layer.

## Package Boundaries

`agentr` intentionally excludes:

- raw LLM provider clients
- email, Telegram, and X backends
- domain-specific trading/data agents
- autonomous execution engines

These concerns should live in adjacent packages such as `inferencer` and `dispatchr`.
