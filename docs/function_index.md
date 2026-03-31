# Function Index

## Core R6 Classes

| Object | Purpose |
| --- | --- |
| `CognitiveState` | Minimal cognitive state container with update hooks |
| `AffectiveState` | Affective layer with inertia-aware updates |
| `AgentCore` | Minimal agent container for cognition, affect, and scaffolding |
| `Scaffolder` | Human-in-the-loop workflow elicitation interface |
| `WorkflowProposal` | Public workflow proposal lifecycle object |
| `WorkflowProposalState` | Public approved-workflow and proposal-history state container |

## Workflow Helpers

| Function | Purpose |
| --- | --- |
| `workflow_node()` | Create a workflow node record |
| `workflow_edge()` | Create a workflow edge record |
| `new_workflow_spec()` | Build a workflow specification object |
| `validate_workflow_spec()` | Validate workflow structure |
| `save_workflow_spec()` | Save a workflow specification |
| `load_workflow_spec()` | Load a workflow specification |
| `workflow_graph_data()` | Export graph-ready node and edge tables |
| `validate_workflow_proposal()` | Validate a workflow proposal object |
| `save_workflow_proposal()` | Save a workflow proposal |
| `load_workflow_proposal()` | Load a workflow proposal |
| `workflow_proposal_graph_data()` | Export graph-ready node and edge tables from a workflow proposal |

## LLM Scaffolding Bridge

| Function | Purpose |
| --- | --- |
| `scaffolder_action_methods()` | List the methods an LLM may request |
| `build_scaffolder_prompt()` | Build a prompt that describes task, workflow state, and allowed actions |
| `build_implementation_prompt()` | Build an implementation-planning prompt for a coding agent |
| `build_workflow_extraction_prompt()` | Build a prompt to reverse-engineer existing code into an agentr workflow spec |
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
| `save_agent()` | Save an `agentr` core object |
| `load_agent()` | Load an `agentr` core object |
| `backup_agent()` | Save a timestamped backup |
| `load_json_file()` | Load JSON files |
| `load_yaml_file()` | Load YAML files |
| `inferencer_available()` | Detect optional `inferencer` availability |
| `inferencer_integration()` | Build optional integration metadata |
