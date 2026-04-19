# Function Index

## Core R6 Classes

| Object | Purpose |
| --- | --- |
| `CognitiveState` | Minimal cognitive state container with update hooks |
| `AffectiveState` | Affective layer with inertia-aware updates |
| `AgentCore` | Minimal agent container for cognition, affect, and scaffolding |
| `CognitiveConfig` | Cognitive-layer config for `RWM` |
| `AffectiveConfig` | Affective-layer config for `RWM` |
| `RWMConfig` | Reflective working-memory config |
| `PGConfig` | Planning and goal-management config |
| `AEConfig` | Action-execution config |
| `IACConfig` | Interaction and communication config |
| `LAConfig` | Learning and adaptation config |
| `SubsystemSpec` | Sparse subsystem inventory for an agent design |
| `AgentSpec` | Public intelligent-agent design artifact |
| `AgentScaffoldState` | Approved agent-design state container |
| `IntelligentAgent` | Runtime-oriented container around an `AgentSpec` |
| `Scaffolder` | Human-in-the-loop intelligent-agent scaffolding interface |
| `WorkflowProposal` | Public workflow proposal lifecycle object |
| `WorkflowProposalState` | Public approved-workflow and proposal-history state container |

## Workflow Helpers

| Function | Purpose |
| --- | --- |
| `workflow_node()` | Create a workflow node record |
| `workflow_edge()` | Create a workflow edge record |
| `new_workflow_spec()` | Build a workflow specification object |
| `workflow_spec_from_json()` | Build a workflow specification from extracted JSON |
| `import_extracted_workflow()` | Import extracted workflow JSON and optionally store it on a `Scaffolder` |
| `validate_workflow_spec()` | Validate workflow structure |
| `save_workflow_spec()` | Save a workflow specification |
| `load_workflow_spec()` | Load a workflow specification |
| `workflow_graph_data()` | Export graph-ready node and edge tables |
| `render_workflow_graphviz()` | Render a workflow as Graphviz DOT, DiagrammeR, or SVG |
| `plot_workflow_graph()` | Plot a workflow graph with DiagrammeR |
| `validate_workflow_proposal()` | Validate a workflow proposal object |
| `save_workflow_proposal()` | Save a workflow proposal |
| `load_workflow_proposal()` | Load a workflow proposal |
| `workflow_proposal_graph_data()` | Export graph-ready node and edge tables from a workflow proposal |

## LLM Scaffolding Bridge

| Function | Purpose |
| --- | --- |
| `scaffolder_action_methods()` | List the methods an LLM may request |
| `build_scaffolder_prompt()` | Build a prompt that describes task, workflow state, and allowed actions |
| `build_agent_design_prompt()` | Build a prompt focused on subsystem-first agent design |
| `build_implementation_prompt()` | Build an implementation-planning prompt for a coding agent |
| `build_workflow_extraction_prompt()` | Build a prompt to reverse-engineer existing code into an agentr workflow spec |
| `build_article_workflow_extraction_prompt()` | Build a prompt to infer workflow specs from article-described cases |
| `parse_scaffolder_message()` | Parse machine-readable JSON from an LLM |
| `validate_scaffolder_message()` | Validate requested scaffolding actions |
| `apply_scaffolder_message()` | Translate validated actions into `Scaffolder` method calls |
| `preview_scaffolder_message()` | Preview and optionally store a workflow proposal without mutating the live workflow |
| `collect_scaffolder_questions()` | Collect human-facing prompts from dispatch results or interaction logs |

## Affective Utilities

| Function | Purpose |
| --- | --- |
| `default_emotion_state()` | Create a default affective state |
| `define_random_emotion_state()` | Create a randomized affective state |
| `decay_emotion_state()` | Apply time-based decay |
| `combine_emotions()` | Combine affective dimensions |
| `compute_blended_emotions()` | Derive blended affective states |
| `describe_emotional_state()` | Summarize current affective state |

## Terminal Helpers

| Function | Purpose |
| --- | --- |
| `render_markdown_terminal()` | Render light markdown styling in terminals |
| `terminal_scaffold_input()` | Prompt for user input during scaffolding |
| `terminal_discuss_task()` | Capture free-form terminal feedback into the scaffolder |
| `terminal_ask_node_complete()` | Ask whether a workflow node is complete |
| `terminal_ask_workflow_changes()` | Ask what workflow or edge changes should be made |
| `terminal_ask_node_rule()` | Ask for a node-specific rule |

## Persistence and Serialization

| Function | Purpose |
| --- | --- |
| `save_agent()` | Save a supported `agentr` object, including agent-spec objects |
| `save_agent_spec()` | Save an `AgentSpec` explicitly |
| `load_agent_spec()` | Load an `AgentSpec` explicitly |
| `save_subsystem_spec()` | Save a `SubsystemSpec` explicitly |
| `load_subsystem_spec()` | Load a `SubsystemSpec` explicitly |
| `load_agent()` | Load a supported `agentr` object |
| `backup_agent()` | Save a timestamped backup |
| `load_json_file()` | Load JSON files |
| `load_yaml_file()` | Load YAML files |
| `inferencer_available()` | Detect optional `inferencer` availability |
| `inferencer_integration()` | Build optional integration metadata |

## Scaffolder Design Flow

| Method | Purpose |
| --- | --- |
| `Scaffolder$subsystem_recommendations()` | Return stored subsystem recommendation records |
| `Scaffolder$subsystem_recommendation_rationale()` | Return recommendation rationale for one or all subsystems |
| `Scaffolder$edit_workflow_subsystems()` | Edit workflow-node subsystem ownership incrementally |
| `Scaffolder$propose_agent_spec()` | Store a draft agent-spec proposal |
| `Scaffolder$list_agent_spec_proposals()` | List draft and approved agent-spec proposals |
| `Scaffolder$get_agent_spec_proposal()` | Fetch one stored agent-spec proposal |
| `Scaffolder$discuss_agent_spec_proposal()` | Attach discussion to a draft agent-spec proposal |
| `Scaffolder$approve_agent_spec_proposal()` | Approve a draft agent-spec proposal and optionally its linked workflow proposal |
