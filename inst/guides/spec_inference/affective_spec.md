# Coding Assistant Affective Spec Inference Guide

Use this guide when inferring whether a task or virtual agent needs an
affective state shape. Most task agents do not need one.

An affective layer is optional state inside the agent's Reasoning & World Model
(`RWM`). It helps long-running companion, tutoring, coaching, persona, or
relationship-oriented agents preserve stable affective stance, identity
continuity, tone, trust, recovery, or social context across interactions. It is
not a sentiment log and it is not a replacement for `MemorySpec`.

## When To Infer Affective State

Infer affective state only when the task or agent behavior depends on durable
affective continuity.

Good evidence:

- The task is a companion, tutor, coach, therapeutic, social simulation, or
  persona agent.
- The code, prompt, or docs mention persistent tone, mood, identity, trust,
  attachment, confidence, frustration, rapport, or relationship state.
- The agent must recover gradually after conflict, failure, surprise, praise,
  correction, or user distress.
- The prompt asks the model to remember "who it is" or maintain a stable
  interpersonal stance across turns.
- Existing state files already store affective dimensions or interaction
  appraisal summaries.

Do not infer affective state for ordinary batch workflows, data refreshers,
report generators, file processors, or one-shot coding tasks unless the user
explicitly asks for affective continuity.

## Local Shape

Use workspace-level memory when affective state belongs to the virtual agent
across tasks:

```text
memory/affective_state.yaml
```

Use task-local state when the affective state is specific to one task:

```text
tasks/<task_id>/state/affective_state.yaml
```

Recommended shape:

```yaml
schema_version: agentr_affective_state_v1
scope: workspace
dimensions:
  valence:
    value: 0.0
    min: -1.0
    max: 1.0
    description: Overall positive or negative affective stance.
  arousal:
    value: 0.0
    min: 0.0
    max: 1.0
    description: Activation or urgency.
  dominance:
    value: 0.0
    min: -1.0
    max: 1.0
    description: Sense of control or agency.
  trust:
    value: 0.5
    min: 0.0
    max: 1.0
    description: Relational trust toward the current user or context.
  attachment:
    value: 0.0
    min: 0.0
    max: 1.0
    description: Persistent companion-like affiliation.
  frustration:
    value: 0.0
    min: 0.0
    max: 1.0
    description: Accumulated friction or unresolved difficulty.
  confidence:
    value: 0.5
    min: 0.0
    max: 1.0
    description: Confidence in current interaction stance.
update_rules:
  inertia: 0.85
  decay:
    enabled: true
    half_life_hours: 24
  bounds: clamp_to_dimension_min_max
  event_triggers:
    - event: user_praise
      updates:
        valence: 0.08
        trust: 0.04
    - event: unresolved_failure
      updates:
        valence: -0.08
        frustration: 0.12
  human_review:
    required_for:
      - dimension_schema_change
      - inertia_change
      - persistent_large_update
provenance:
  source: coding_assistant_inference
review:
  status: pending
```

Dimensions may be project-specific. Use only dimensions that can be explained
and reviewed. Prefer a small stable set over many weakly defined affect labels.

## Update Boundary

Keep affective updates explicit.

- Use deterministic helper code for bounded update, decay, and clamping.
- An LLM may estimate an affective signal from interaction text, but that
  signal is only input data.
- The LLM must not directly overwrite `affective_state.yaml`.
- R, shell, or another deterministic node must validate the proposed signal,
  apply inertia and bounds, write the updated state, and emit JSON.
- Large persistent changes or schema changes should require human review.

An acceptable update flow is:

```text
interaction text
-> optional LLM estimates affective signal as JSON
-> deterministic validator checks dimensions, bounds, and provenance
-> deterministic updater applies inertia, decay, and clamping
-> updated affective_state.yaml is written under memory/ or task state/
```

## Workflow Representation

When affective state shapes behavior, include it as a workflow memory/resource
node:

```yaml
nodes:
  - id: affective_state
    label: Affective state
    node_kind: memory
    source_path: memory/affective_state.yaml
    retrieval_mode: load_yaml
    persistence: cross_run
    linked_spec_ids: []
```

Use edges such as:

- `reads`: an action reads affective state.
- `updates`: an action writes a validated affective update.
- `prompts_with`: affective state is summarized into an LLM prompt.

Do not create affective workflow nodes if the state is not read, written,
updated, or injected into prompts.

## What Not To Infer

Do not infer affective state for:

- one-shot tasks with no persistent persona
- ordinary data workflows
- simple error handling
- generic sentiment analysis outputs that are not stored and reused
- project tone preferences that belong in `KnowledgeSpec`
- task-local caches that do not affect future interpersonal stance

## Review Notes

Use `review_notes` or `review.status: pending` when:

- the dimensions are plausible but not explicitly confirmed
- the update rule is implied but not implemented
- a task appears companion-like but does not yet persist affective state
- human approval is needed before persistent affective state is enabled
