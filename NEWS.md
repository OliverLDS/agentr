# agentr news

## agentr 0.2.8.3

Released: 2026-06-24

- Removed examples from the internal `.safe_read_rds()` and `.safe_save_rds()` help pages instead of documenting unexported functions with runnable examples.
- Finalized the CRAN resubmission package after the internal-example cleanup.

## agentr 0.2.8.2

Released: 2026-06-19

- Fixed CRAN incoming feasibility notes by replacing README relative file links with absolute GitHub links.
- Replaced the MIT `LICENSE` file with the CRAN-required DCF license stub for `MIT + file LICENSE`.
- Simplified DESCRIPTION title and wording to avoid incoming spell-check notes in CRAN pretests.

## agentr 0.2.8.1

Released: 2026-06-18

- Prepared CRAN-oriented packaging infrastructure without changing package APIs.
- Added a GitHub Actions `R CMD check --no-manual --as-cran` matrix for macOS, Windows, Ubuntu, and Ubuntu R-devel.
- Updated source-build ignores so repository-only docs, examples, CI files, build artifacts, and local metadata are excluded from CRAN tarballs.
- Removed a tracked `.DS_Store` artifact and made the function-index documentation test safe for built-package checks.
- Shortened one generated Rd usage default to avoid PDF manual line-width notes.

## agentr 0.2.8

Released: 2026-06-16

- Added coding-assistant guidance for optional affective state inference in companion, tutoring, coaching, persona, and long-running relationship-oriented agents.
- Documented local affective-state shapes such as `memory/affective_state.yaml` and task-local `state/affective_state.yaml`, including dimensions, bounds, inertia, decay, event triggers, and human-review rules.
- Updated task code-construction guidance so affective updates use deterministic validation, bounded update and decay, optional LLM signal estimation, and no direct LLM overwrite of canonical affective state.
- Linked affective-state inference from the full-stack task-spec wrapper while keeping it explicitly optional for most task agents.

## agentr 0.2.7.13

Released: 2026-06-08

- Added `node_kind = "status"` for workflow-visible status, mode, checkpoint, and error markers that are not executable actions or resource nodes.
- Updated design review HTML so status nodes remain visible in workflow graphs with a lightweight dashed marker style.
- Improved orthogonal workflow edge routing by assigning separate side ports when multiple edges touch the same side of a node.
- Updated coding-assistant WorkflowSpec inference guidance to use status nodes for failure or recovery states without drawing every possible upstream failure edge.

## agentr 0.2.7.12

Released: 2026-06-08

- Tightened WorkflowSpec inference guidance so branch metadata is reserved for real conditional fan-out edges.
- Clarified that guarded sequential steps should record guards on nodes or edge notes, not in `edge.condition`.
- Updated workflow-only inference validation and public WorkflowSpec docs to prevent condition-only sequential edges from being rendered as branches.

## agentr 0.2.7.11

Released: 2026-06-06

- Reordered the design review side panel so linked knowledge, memory, and resources appear above the detail inspector.
- Extended subworkflow modals with their own resource context, detail inspector, and structured feedback controls.
- Scoped subworkflow node, edge, and resource clicks to the modal inspector while preserving the shared feedback JSON export.

## agentr 0.2.7.10

Released: 2026-06-06

- Changed design review HTML so clicking a subworkflow badge opens the child workflow in an in-page modal instead of reserving permanent main-page space for task previews.
- Updated `render_task_preview()` to resolve task-local `subworkflow_ref` paths and embed child workflow specs into the standalone review bundle when available.
- Clarified workflow/task-family guidance so `subworkflow_ref` is the preferred editable source and `nested_workflow` is review-bundle data.

## agentr 0.2.7.9

Released: 2026-06-06

- Updated design review HTML so the main workflow graph shows action nodes only, keeping knowledge, memory, file, API, schema, and other resource nodes out of the action-flow diagram.
- Added a contextual "Knowledge, memory, and resource schema" panel that shows only resources linked to the selected action node through resource edges or spec references.
- Restored subworkflow badges for workflow nodes that use either embedded nested workflows or `subworkflow_ref` links.

## agentr 0.2.7.8

Released: 2026-06-06

- Added workflow data/resource node metadata with `node_kind` values for action, knowledge, memory, file, API, schema, and generic data nodes.
- Added resource-oriented workflow edge semantics for reads, writes, updates, prompt injection, schema validation, and produced artifacts.
- Updated design review HTML so process-layout workflows place resource nodes in a resource lane, color them separately, label resource edges, and expose source/retrieval/persistence/spec-link metadata in the detail inspector.
- Moved the standalone review renderer JavaScript and CSS into package assets under `inst/review/` while preserving the public `design_review_html()` and `export_design_review_html()` R APIs.
- Updated coding-assistant inference guidance so `KnowledgeSpec` and `MemorySpec` are inferred only when workflow resource nodes, references, retrieval paths, update paths, or validation dependencies make them behavior-shaping.

## agentr 0.2.7.7

Released: 2026-06-06

- Removed the unused first-class `KnowledgeGraphSpec` surface and its dedicated proposal/message lifecycle.
- Reframed graph structure as a representation shape embedded in `KnowledgeSpec` or `MemorySpec`, rather than a standalone top-level spec.
- Updated task-local discovery and coding-assistant guidance so projects use `workflow_spec.yaml`, optional `memory_spec.yaml`, and optional `knowledge_spec.yaml`; graph-shaped content now belongs under `graph:` inside knowledge or memory specs.
- Preserved graph rendering helpers for `KnowledgeSpec`, `MemorySpec`, and plain `list(nodes, edges)` graph representations.

## agentr 0.2.7.6

Released: 2026-06-05

- Improved review HTML layout for memory, narrative-knowledge, and graph-knowledge mini-graphs.
- Removed the synthetic narrative `knowledge_spec` hub from fallback knowledge maps so dense knowledge items no longer crowd behind one root node.
- Added edge-lane fanout, larger node spacing, and relation-label backgrounds in review mini-graphs to reduce node, edge, and edge-label overlap.

## agentr 0.2.7.5

Released: 2026-06-05

- Reorganized package-shipped coding-assistant guides under `inst/guides/` into wrapper, spec-inference, and code-construction sections.
- Renamed the full project inference wrapper to `full_stack_task_spec_inference.md`.
- Added `workflow_only_task_spec_inference.md` for simpler tasks that only need `workflow_spec.yaml`.
- Split spec-specific inference guidance into `spec_inference/workflow_spec.md`, `memory_spec.md`, `knowledge_spec.md`, and `knowledge_graph_spec.md`.
- Moved code construction guidance under `code_construction/`.

## agentr 0.2.7.4

Released: 2026-06-05

- Condensed the README into a concise package overview with links to subject-specific documentation.
- Added `docs/r_function_examples.md` for R helper snippets used by humans for inspection and by coding assistants for package-conformant scaffolding.
- Clarified coding-assistant-first scaffolding while preserving R functions as the standardized spec, validation, rendering, and prompt-helper surface.
- Reframed subsystem/capability labels in docs and prompt contracts as optional diagnostic annotations rather than primary runtime specs.

## agentr 0.2.7.3

Released: 2026-06-05

- Reframed README and package metadata around specification, review, and coding-assistant scaffolding rather than a cognitive/human-interaction core.
- Clarified that subsystem labels are optional diagnostic node-labeling metadata, not first-class runtime specs.
- Removed the stale `docs/manuscript/` asset set and `docs/manuscript_assets.md`.
- Replaced the old conceptual-figure hub with guidance to generate figures from package-native workflow, memory-schema, schema-shape, knowledge-graph, and review-HTML renderers.

## agentr 0.2.7.2

Released: 2026-06-05

- Moved the workspace CLI wrapper to `inst/scripts/agentr-cli.R` and kept the same `-h`/`--help` parser semantics.
- Added task-local preview helpers: `render_task_preview()` and `render_task_previews()`.
- Extended the standalone design review page to render memory-schema and knowledge graphs in addition to the workflow graph.
- Preserved the package-shipped coding-assistant guides and updated downstream documentation to the new script location.

## agentr 0.2.7.1

Released: 2026-06-05

- Added memory-schema graph helpers: `memory_schema_graph_data()` and `render_memory_schema_graphviz()`.
- Added schema-shape graph helpers for workflow-node `input_schema` and `output_schema`: `schema_shape_graph_data()` and `render_schema_shape_graphviz()`.
- Documented memory/schema rendering in the README, MemorySpec guide, WorkflowSpec guide, and function index.
- Added regression coverage for memory-schema and schema-shape DOT, DiagrammeR, and SVG rendering paths.

## agentr 0.2.7

Released: 2026-06-04

- Added a coding-assistant scaffolding guide that explains repository inspection, task-local YAML specs, review HTML, and Git-backed spec evolution as a complementary path to proposal-state scaffolding.
- Added task-local spec helpers: `task_spec_paths()`, `discover_task_specs()`, `load_task_specs()`, and `validate_task_specs()`.
- Linked the coding-assistant scaffolding path from the README, documentation index, proposal lifecycle guide, and package-shipped coding-assistant guides.
- Clarified that proposal objects and Git history are separate versioning mechanisms for different scaffolding contexts.
- Added tests for task-local spec discovery, loading, validation, required-spec reporting, and function-index export coverage.

## agentr 0.2.6.15

Released: 2026-05-31

- Reorganized public documentation around a new `docs/index.md` landing page, YAML-first editable specs, and current review-layer behavior.
- Archived completed implementation plans under `docs/archive/plans/` and moved manuscript figures and tables under `docs/manuscript/`.
- Added dedicated workflow-spec, knowledge-graph-spec, spec-format, memory-message, and knowledge-message guides.
- Expanded proposal-lifecycle documentation across workflow, agent-spec, memory, narrative-knowledge, and graph-knowledge paths.
- Refreshed manuscript figures and tables for the current object model, manual-LLM review loop, and corrected `IAC` semantics.
- Added regression coverage requiring every exported package object to remain represented in the documentation function index.

## agentr 0.2.6.14

Released: 2026-05-30

- Fixed remaining wide review-diagram truncation by accounting for right-extending edge rails in the workflow SVG width budget.
- Preserved the horizontal scroll wrapper so oversize workflow charts can expose both left and right edge routing.

## agentr 0.2.6.13

Released: 2026-05-30

- Fixed wide review-diagram clipping by wrapping workflow SVG output in an explicit horizontal scroll container.
- Kept full chart width available inside the review panel so right-side nodes and edges remain reachable by scrolling.

## agentr 0.2.6.12

Released: 2026-05-29

- Added a lightweight nested-workflow badge to review-diagram nodes that contain child workflows.
- Kept the badge visually minimal so nested nodes remain distinguishable without changing the graph layout.

## agentr 0.2.6.11

Released: 2026-05-29

- Fixed process-layout branch edge anchoring for orthogonal review diagrams.
- Routed conditional branch edges from the left or right midpoint of the decision node into the top midpoint of the branch target.
- Preserved dashed branch styling while restoring correct arrow direction and endpoint placement.

## agentr 0.2.6.10

Released: 2026-05-29

- Hardened the design-review `process` layout for conditional branch blocks in dense workflow diagrams.
- Widened process branch lanes so sibling condition labels have more room and are less likely to overlap.
- Routed branch rejoin edges on the side of their originating branch lane and pushed long feedback-loop rails farther left of branch nodes.

## agentr 0.2.6.9

Released: 2026-05-29

- Refined the design-review `process` layout so mutually exclusive branch groups render as centered decision blocks.
- Placed branch alternatives horizontally around the decision node and centered common join nodes below converging branches.
- Kept loop and back-edge routing separate from branch decision-block routing.

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
- Added guidance for task-local `docs/` artifacts, `knowledge/agent_paths.json` workspace-path loading, side-effect-safe validation practices, and supported `KnowledgeSpec` item types.
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
- Moved historical release planning notes into `docs/archive/plans/` so top-level documentation stays focused on current package and manuscript materials.
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
