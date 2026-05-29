# agentr news

## agentr 0.2.6.8

Released: 2026-05-29

- Made the design-review `process` layout branch-aware so multiple conditional branch targets from the same source are placed into right-side branch lanes even when they later rejoin the main workflow.
- Added orthogonal rejoin routing for branch-lane nodes returning to the process spine.
- Added regression coverage for conditional branch placement in the process layout.

## agentr 0.2.6.7

Released: 2026-05-29

- Added first-class workflow edge branch metadata: `condition`, `branch_group`, and `mutually_exclusive`.
- Preserved branch edge metadata through workflow JSON/YAML load/save and design-review payload export.
- Rendered conditional branch edges visibly in design-review HTML with branch styling, condition labels, and edge-inspector fields.
- Updated workflow extraction prompts and coding-assistant guidance to represent conditional routes through explicit edge fields.

## agentr 0.2.6.6

Released: 2026-05-24

- Added YAML save/load helpers for workflow, memory, knowledge, and knowledge-graph specs while preserving JSON and RDS compatibility.
- Made task-local YAML specs the preferred editable source of truth in coding-assistant task-spec guidance.
- Hardened design-review HTML against scalar-or-array `knowledge_refs` payloads and preserved schema-array fields such as `knowledge_refs` and JSON-schema `required` during editable spec serialization.
- Added `inst/guides/coding_assistant_task_code_construction.md` for converting approved `agentr` specs into task-local executable code without expanding `agentr` into a runtime executor.

## agentr 0.2.6.5

Released: 2026-05-22

- Added `inst/guides/coding_assistant_task_spec_inference.md` as a coding-assistant inference contract for task codebases.
- Aligned the guide with node-folder subworkflow conventions under `tasks/<task_id>/nodes/<subworkflow_node_id>/`.
- Added guidance for task-local `docs/` artifacts, `memory/agent_paths.json` path-memory loading, side-effect-safe validation practices, and supported `KnowledgeSpec` item types.
- Clarified that generated specs are descriptive/reviewable artifacts and should not introduce runtime behavior beyond observed task code.

## agentr 0.2.6.4

Released: 2026-05-21

- Added task-family helpers so one workspace can group multiple related tasks under a shared root workflow while keeping each child task reviewable through its own subworkflow reference.
- Added task-family design documentation and review-page task tabs so the main browser preview can switch between child tasks instead of forcing all nested workflows into one narrow detail panel.
- Improved design-review rendering so nested workflow clicks preserve the selected preview context and the right-side detail panel continues to show the clicked node.

## agentr 0.2.6.3

Released: 2026-05-20

- Added workflow-node `subworkflow_ref`, `input_schema`, `output_schema`, and `nested_workflow` fields for hierarchical workflow review and schema inspection.
- Added a right-side node-detail panel in design-review HTML, with clickable workflow nodes/cards and local nested-workflow rendering when available.
- Added constrained scaffolder actions `set_node_schema` and `set_node_nested_workflow`.
- Added `build_node_detail_prompt()` and workspace/CLI support for node-scoped workflow revisions through `apply_node_detail_message()` and `--node-id`.
- Updated workflow field docs, CLI lifecycle docs, scaffolder message schema, and tests for node-detail proposal flows.

## agentr 0.2.6.2

Released: 2026-05-20

- Hardened workspace CLI argument handling around explicit `--` options and made initial workflow imports create pending workflow proposals instead of silently mutating approved state.
- Made review export work for workflow-only proposal states when no approved `AgentSpec` is available.
- Added design-review workflow graph layout controls for `grid`, `layered`, `swimlane`, and loop-aware `process` layouts, with `curved`, `straight`, and `orthogonal` edge styles.
- Improved review graph rendering with wrapped SVG labels, scrollable graph panels, swimlane stacking, cycle-aware layout warnings, and process-spine rendering for loop-heavy workflows.
- Relaxed scaffolder-message handling for common LLM JSON drift while still rejecting unsupported actions and preserving constrained dispatch semantics.

## agentr 0.2.6.1

Released: 2026-05-20

- Added generic workspace lifecycle helpers and a thin CLI wrapper for manual prompt/response scaffolding loops across workflow, agent, memory, and knowledge design.
- Added workspace-scoped proposal listing, approval, rejection, review HTML export, and implementation handoff prompt helpers.
- Updated design-review workflow graph rendering so long labels wrap in SVG instead of being hard-truncated.

## agentr 0.2.6

Released: 2026-05-17

- Added standalone, offline HTML review export with `design_review_html()` and `export_design_review_html()`.
- Extended design-review data support with `new_design_review_spec()`, workflow-only, workflow-proposal, and knowledge-only inputs.
- Added design-feedback issue types, target ids, RDS persistence helpers, target-id validation warnings, non-mutating preview, and scaffolder-routed application.
- Added tests covering review HTML generation, feedback save/load, feedback validation, review-data adapters, and feedback application.
- Added review-layer documentation clarifying that browser output is for inspection and structured feedback, not execution.

## agentr 0.2.5.6

Released: 2026-05-17

- Added `DesignReviewSpec` as a data contract for a future JS/HTML design review layer.
- Added `build_design_review_data()` to package workflow graphs, memory schemas, narrative knowledge, graph knowledge, proposal states, and feedback schema into one review bundle.
- Added structured design-feedback helpers: `design_feedback_item()`, `validate_design_feedback()`, and `parse_design_feedback_json()`.
- Added tests for review bundle construction, proposal-state snapshots, and structured feedback validation.

## agentr 0.2.5.5

Released: 2026-05-17

- Added `MemoryProposal` and `MemoryProposalState` so memory schemas can move through proposal, discussion, approval, rejection, and supersession.
- Added `KnowledgeGraphProposal` and `KnowledgeGraphProposalState` so graph knowledge can use the same review lifecycle as workflow and narrative knowledge.
- Added memory prompt builders and constrained message handlers for proposing, revising, discussing, approving, rejecting, and human-querying memory schemas.
- Added knowledge-graph prompt builders and constrained message handlers for extracting, revising, discussing, approving, rejecting, and human-querying graph knowledge.
- Added tests covering lifecycle transitions, preview non-mutation, constrained JSON application, and unsafe action rejection for memory and graph knowledge loops.

## agentr 0.2.5.4

Released: 2026-05-17

- Promoted `agentr_knowledge_graph_spec` from a visualization-only projection into a first-class graph-knowledge representation.
- Added graph node metadata for memory type, knowledge form, provenance, review, and scope.
- Added graph edge metadata for relation type, memory type, provenance, review, and scope.
- Added `add_knowledge_graph_node()`, `add_knowledge_graph_edge()`, `save_knowledge_graph_spec()`, and `load_knowledge_graph_spec()`.
- Extended `KnowledgeSpec` so it can hold narrative items, first-class graph knowledge, and future vector-reference metadata.
- Clarified that `knowledge_graph_from_spec()` creates a projection graph from narrative knowledge items.

## agentr 0.2.5.3

Released: 2026-05-17

- Added first-class `MemorySpec` support for context, semantic, episodic, and procedural memory schemas.
- Added memory-field records with persistence policies for session memory, cold-start RDS state, JSONL traces, external stores, and non-persistent fields.
- Extended `AgentSpec` with optional `memory_spec` while preserving existing `state_spec` and `state_requirements` compatibility.
- Added `save_memory_spec()`, `load_memory_spec()`, `validate_memory_spec()`, `memory_types()`, and `memory_persistence_policies()`.
- Added MemorySpec tests and updated the complete AgentSpec fixture to cover memory schema round trips.

## agentr 0.2.5.2

Released: 2026-05-17

- Tightened README wording so patch releases do not overstate the historical shift to agent-spec-first scaffolding.
- Added explicit `state_spec`, `interface_spec`, and `autonomy_spec` examples for `AgentSpec` to prepare the package surface for design-review artifacts.
- Added a reusable complete `AgentSpec` test fixture and round-trip tests covering `knowledge_spec`, `state_spec`, `interface_spec`, `autonomy_spec`, workflow knowledge references, and implementation-prompt knowledge selection.
- Clarified generated knowledge-graph documentation and examples so the graph surface is framed as review and visualization support for curated `KnowledgeSpec` content.
- Added the `v0.2.6` implementation plan for the standalone JS/HTML design-review and structured-feedback layer.

## agentr 0.2.5.1

Released: 2026-05-13

- Added `agentr_knowledge_graph_spec` helpers for structuring graph-ready knowledge nodes and edges from curated `KnowledgeSpec` items.
- Added `knowledge_graph_from_spec()`, `knowledge_graph_data()`, `render_knowledge_graphviz()`, and `plot_knowledge_graph()` for DiagrammeR/Graphviz-based knowledge visualization.
- Updated the README, function index, generated manual pages, and tests to cover the new knowledge-graph surface.

## agentr 0.2.5

Released: 2026-04-29

- Refactored subsystem semantics to the corrected five-module schema: `RWM` = Reasoning & World Model, `PG` = Perception & Grounding, `AE` = Action Execution, `LA` = Learning & Adaptation, and `IAC` = Inter-Agent Communication.
- Added `KnowledgeSpec`, `KnowledgeProposal`, and `KnowledgeProposalState` plus persistence, validation, and constrained knowledge-prompt/message helpers.
- Extended `AgentSpec` and workflow nodes with knowledge references, autonomy metadata, ownership fields, and transitional trace requirements.
- Added decision-trace and reflection-trace helpers for progressive codification of human-owned reasoning.
- Added concept docs for `KnowledgeSpec`, cold-vs-hot runtime, and the capability-autonomy landscape.

## agentr 0.2.4.3

Released: 2026-04-23

- Hardened Graphviz string escaping in workflow rendering so backslashes and apostrophes no longer break `render_workflow_graphviz(..., as = "svg")` on article-derived workflows.
- Restored correct Graphviz label line-break rendering after the escaping hardening by preserving intended `\n` label breaks while still escaping unsafe string content.
- Added regression tests covering backslash-heavy labels, apostrophes in wrapped labels, and multiline label rendering through the SVG export path.

## agentr 0.2.4.2

Released: 2026-04-20

- Added `article_workflow_specs_from_json()` to import multi-workflow article extraction JSON into validated workflow specifications.
- Refactored workflow JSON import internals so single-workflow and article-level extraction paths share stricter node and edge normalization.
- Made Graphviz tooltips opt-in in `render_workflow_graphviz()` and `plot_workflow_graph()` to avoid DiagrammeR/Viz.js parse failures from long article-derived prose.
- Updated README examples, function index docs, generated manual pages, and tests for article workflow import and robust DiagrammeR rendering.

## agentr 0.2.4.1

Released: 2026-04-19

- Switched workflow graph rendering guidance from base `igraph` plotting to a DiagrammeR/Graphviz-first path for clearer workflow DAG visualization.
- Enhanced `render_workflow_graphviz()` with wrapped labels, human-gate node styling, tooltips, optional same-rank grouping, and SVG export through `DiagrammeRsvg`.
- Kept `plot_workflow_graph()` as the public plotting helper while making it return a DiagrammeR graph.
- Added `build_article_workflow_extraction_prompt()` for inferring agentr-compatible workflow specifications from article-described cases.
- Updated README, function index, lifecycle docs, generated manual pages, and tests for the new visualization and article-extraction paths.

## agentr 0.2.4

Released: 2026-04-06

- Reorganized documentation assets by adding dedicated figure and table indexes plus a manuscript-assets overview page.
- Expanded the manuscript-oriented figure set with standalone source, render, and caption artifacts for the main conceptual diagrams.
- Expanded the manuscript-oriented table set with paired Markdown and LaTeX outputs for core framework, subsystem, workflow, lifecycle, and case-comparison summaries.
- Moved historical release planning notes into `docs/plans/` so top-level documentation stays focused on current package and manuscript materials.
- Updated package-level documentation links and version references to align with the expanded documentation structure.

## agentr 0.2.3

Released: 2026-04-03

- Added `workflow_spec_from_json()` so workflow-extraction JSON can be converted directly into a validated `agentr_workflow_spec`.
- Added `import_extracted_workflow()` to bridge extracted JSON into the normal `Scaffolder` proposal and approval flow.
- Added `render_workflow_graphviz()` for Graphviz DOT and optional `DiagrammeR` rendering of inferred workflows.
- Added `plot_workflow_graph()` for improved DAG-oriented visualization using `igraph`.
- Expanded README examples, function-index docs, generated manual pages, and tests for workflow import and rendering helpers.

## agentr 0.2.2

Released: 2026-04-01

- Added first-class draft agent-design proposal flow inside `Scaffolder`, including proposal creation, listing, discussion, and approval methods.
- Added a clearer bridge from workflow proposals into agent-spec approval so a linked workflow proposal can seed and be approved alongside an agent-spec proposal.
- Improved subsystem recommendation usability with explicit rationale accessors and richer prompt payloads that surface recommendation records and draft design proposals.
- Added incremental workflow-node ownership editing through `edit_workflow_subsystems()`, making subsystem ownership changes easier than full replacement.
- Expanded tests to cover the draft design workflow, incremental ownership editing, and workflow-proposal-to-agent-spec approval bridging.

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
