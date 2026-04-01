# agentr news

## agentr 0.2.1

Released: 2026-04-01

- Hardened `AgentSpec` and `SubsystemSpec` validation with stronger subsystem-to-workflow consistency checks, including validation of node subsystem labels against the selected subsystem set.
- Added explicit persistence helpers for the new public design objects: `save_agent_spec()`, `load_agent_spec()`, `save_subsystem_spec()`, and `load_subsystem_spec()`.
- Improved interactive ergonomics by adding compact print methods for subsystem configs, `SubsystemSpec`, `AgentSpec`, `AgentScaffoldState`, and `IntelligentAgent`.
- Expanded test coverage for mixed config payloads, explicit design-object persistence, and validation failures around inconsistent subsystem selections.

## agentr 0.2.0

Released: 2026-04-01

- Shifted the package toward agent-spec-first scaffolding by adding public `AgentSpec`, `SubsystemSpec`, `AgentScaffoldState`, and `IntelligentAgent` classes.
- Added public subsystem configuration classes for sparse subsystem selection: `RWMConfig`, `PGConfig`, `AEConfig`, `IACConfig`, `LAConfig`, `CognitiveConfig`, and `AffectiveConfig`.
- Extended `Scaffolder` with subsystem recommendation, subsystem selection, workflow node subsystem labeling, and approved agent-spec state while preserving the existing workflow-first APIs.
- Added `build_agent_design_prompt()` and extended implementation-prompt normalization so `AgentSpec` and `IntelligentAgent` inputs can drive implementation handoff directly.
- Expanded persistence support and tests to cover sparse agent design flows alongside the existing workflow proposal lifecycle.

## agentr 0.1.9

Released: 2026-03-31

- Added public `WorkflowProposal` and `WorkflowProposalState` R6 classes so workflow proposal lifecycle handling is available through dedicated stateful objects.
- Integrated `Scaffolder` with `WorkflowProposalState` while preserving the existing top-level proposal review methods.
- Updated proposal persistence helpers to work with the new public proposal class objects.
- Expanded lifecycle docs and examples to show direct use of public proposal and proposal-state classes.

## agentr 0.1.8

Released: 2026-03-31

- Clarified the workflow lifecycle docs so elicitation, proposal review and approval, and implementation or extraction handoff are documented as separate stages.
- Promoted proposal persistence helpers into the documented package surface, including validation, save/load, and graph export support for workflow proposals.
- Added a proposal lifecycle document and expanded README examples to show how proposals can be persisted and reviewed outside a live `Scaffolder`.
- Added proposal print behavior and test coverage for exported proposal persistence helpers.

## agentr 0.1.7

Released: 2026-03-31

- Refactor `Scaffolder` internals into clearer workflow, proposal, dispatch, and prompt helper modules while preserving the current top-level UX.
- Formalize workflow proposals with fixed statuses, transition rules, and a stable internal object shape.
- Keep the approved workflow separate from pending proposal history so implementation handoff continues to use approved state only.
- Prevent approved proposals from being silently reopened through discussion, and explicitly supersede older active proposals when a newer proposal is approved.
- Add shared internal prompt-contract helpers so scaffolder, implementation, and workflow-extraction prompt builders follow the same schema discipline.
- Add lifecycle-oriented tests around proposal discussion, approval, supersession, preview, and implementation handoff boundaries.
- Add proposal persistence and graph helpers for internal round-trip and visualization support.

## agentr 0.1.6.2

Released: 2026-03-31

- Added `preview_scaffolder_message()` plus workflow proposal storage and approval methods so reasoning-model DAGs can be previewed, discussed, and approved before they replace the live workflow.
- Added explicit proposal-management methods on `Scaffolder`, including proposal listing, lookup, discussion, and approval.
- Extended Markdown scaffolder prompts to prefer downloadable `.json` file output in chatbox reasoning UIs, reducing long inline JSON copy-paste issues.
- Extended `parse_scaffolder_message()` and `apply_scaffolder_message()` to accept downloaded `.json` file paths in addition to raw JSON strings and parsed lists.
- Added `build_implementation_prompt()` for handing mature workflow specs to coding agents such as Codex as implementation-planning prompts.
- Added `build_workflow_extraction_prompt()` for reverse-engineering existing ad hoc code into an `agentr`-compatible workflow specification.
- Expanded README examples, function index entries, schema docs, tests, and generated manual pages for the new planning, extraction, preview, and review flows.

## agentr 0.1.6.1

Released: 2026-03-31

- Hardened `apply_scaffolder_message()` for real reasoning-model output by accepting direct `decompose_task.args.nodes` and `decompose_task.args.edges` payloads in addition to nested `suggestions`.
- Added dispatch-side argument normalization so newer message payloads still work when a loaded `Scaffolder$decompose_task()` method only accepts the older `suggestions` signature.
- Resolved decomposition edge references by node label as well as generated node id, which makes model-produced DAG payloads more robust in practice.
- Added regression tests for direct node/edge decomposition payloads and legacy-signature dispatch compatibility.
- Updated the README reasoning-loop example to show `inferencer::query_openrouter(prompt_json, max_tokens = 4000)` as a concrete model-call path.

## agentr 0.1.6

Released: 2026-03-30

- Expanded `Scaffolder` into a more realistic human-in-the-loop loop with persistent task evaluation artifacts, free-form discussion rounds, workflow-level review, and node-level review.
- Added first-class workflow editing through node add/remove/insert operations and edge add/remove behavior instead of treating all human updates as one coarse patch.
- Extended workflow schema with review-oriented fields including `review_status`, `review_notes`, `review_confidence`, plus richer edge metadata and stronger workflow validation.
- Integrated terminal scaffolding helpers into actual scaffolder state updates so terminal prompts can feed back into discussion, rule capture, and review state.
- Updated the machine-readable scaffolder bridge to expose `discuss_task`, `review_workflow`, `review_node`, and `edit_workflow`, while keeping `apply_human_feedback()` as a compatibility path.
- Refreshed README examples, architecture notes, schema docs, tests, and generated manual pages for the new discussion-and-review model.

## agentr 0.1.5

Released: 2026-03-29

- Added dual scaffolder prompt formats: JSON for SDK or tool usage and Markdown for manual copy-paste into chat interfaces.
- Hardened scaffolder message validation and dispatch, with richer normalized results from `apply_scaffolder_message()`.
- Added workflow graph export helpers for external DAG visualization workflows.
- Added workflow specification persistence helpers for saving and loading scaffolding output independently of the full agent object.
- Improved README examples and scaffolder schema documentation around the constrained LLM bridge.

## agentr 0.1.4

Released: 2026-03-29

- Added the initial LLM scaffolding bridge so external reasoning systems can inspect workflow state through prompts and return machine-readable actions.
- Introduced prompt generation, JSON parsing, method-level validation, reference validation, and constrained action dispatch for scaffolder operations.
- Formalized `apply_scaffolder_message()` as the translation layer from validated model output into concrete `Scaffolder` method calls.
- Documented the machine-readable scaffolder message schema and added end-to-end examples for human-guided workflow elicitation.
