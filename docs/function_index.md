# Function Index

## Core R6 Classes

| Object | Purpose |
| --- | --- |
| `CognitiveState` | Minimal cognitive state container with update hooks |
| `AffectiveState` | Affective layer with inertia-aware updates |
| `AgentCore` | Minimal agent container for cognition, affect, and scaffolding |
| `CognitiveConfig` | Cognitive-layer config for `RWM` |
| `AffectiveConfig` | Affective-layer config for `RWM` |
| `RWMConfig` | Reasoning and world-model config |
| `PGConfig` | Perception and grounding config |
| `AEConfig` | Action-execution config |
| `IACConfig` | Inter-agent communication config |
| `LAConfig` | Learning and adaptation config |
| `SubsystemSpec` | Sparse diagnostic subsystem inventory for an agent design |
| `AgentSpec` | Public intelligent-agent design artifact |
| `KnowledgeSpec` | Curated knowledge specification |
| `MemorySpec` | Context, semantic, episodic, and procedural memory schema |
| `KnowledgeProposal` | Proposal object for one knowledge item |
| `KnowledgeProposalState` | Approved knowledge plus knowledge proposal history |
| `agentr_knowledge_graph_spec` | Knowledge-graph specification object |
| `MemoryProposal` | Proposal object for candidate memory schema |
| `MemoryProposalState` | Approved memory schema plus proposal history |
| `KnowledgeGraphProposal` | Proposal object for candidate graph knowledge |
| `KnowledgeGraphProposalState` | Approved graph knowledge plus proposal history |
| `DesignReviewSpec` | Review-layer data bundle for workflow, memory, knowledge, graph, proposal, and feedback sections |
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
| `workflow_spec_from_yaml()` | Build a workflow specification from YAML |
| `article_workflow_specs_from_json()` | Build workflow specifications from article extraction JSON |
| `import_extracted_workflow()` | Import extracted workflow JSON and optionally store it on a `Scaffolder` |
| `validate_workflow_spec()` | Validate workflow structure |
| `save_workflow_spec()` | Save a workflow specification as RDS, JSON, or YAML |
| `save_workflow_spec_json()` | Save a workflow specification as JSON |
| `save_workflow_spec_yaml()` | Save a workflow specification as YAML |
| `load_workflow_spec()` | Load a workflow specification from RDS, JSON, or YAML |
| `load_workflow_spec_json()` | Load a workflow specification from JSON |
| `load_workflow_spec_yaml()` | Load a workflow specification from YAML |
| `task_family_metadata()` | Create metadata for a root workflow that groups related child tasks |
| `child_task_node()` | Create a workflow node that represents one child task |
| `new_task_family_workflow()` | Create a root task-family workflow spec |
| `add_child_task_node()` | Add a child-task node and update task-family metadata |
| `set_workflow_node_owner()` | Set one workflow node owner |
| `set_workflow_node_automation_status()` | Set one workflow node automation status |
| `mark_node_human_owned()` | Mark a workflow node as human-owned |
| `mark_node_agent_owned()` | Mark a workflow node as agent-owned |
| `workflow_graph_data()` | Export graph-ready node and edge tables |
| `render_workflow_graphviz()` | Render a workflow as Graphviz DOT, DiagrammeR, or SVG |
| `plot_workflow_graph()` | Plot a workflow graph with DiagrammeR |
| `validate_workflow_proposal()` | Validate a workflow proposal object |
| `save_workflow_proposal()` | Save a workflow proposal |
| `load_workflow_proposal()` | Load a workflow proposal |
| `workflow_proposal_graph_data()` | Export graph-ready node and edge tables from a workflow proposal |
| `schema_shape_graph_data()` | Export graph-ready node and edge tables for a workflow-node input/output schema |
| `render_schema_shape_graphviz()` | Render a workflow-node input/output schema as Graphviz DOT, DiagrammeR, or SVG |
| `task_spec_paths()` | Return conventional task-local spec paths |
| `discover_task_specs()` | Discover task-local workflow, memory, knowledge, and graph YAML specs |
| `load_task_specs()` | Load existing task-local YAML specs |
| `validate_task_specs()` | Validate existing or required task-local YAML specs |
| `render_task_preview()` | Render one task-local review HTML file from workflow, memory, knowledge, and graph YAML specs |
| `render_task_previews()` | Render review HTML files for all discovered task-local workflow specs under a workspace |

## Memory Helpers

| Function | Purpose |
| --- | --- |
| `memory_field()` | Create one memory-field record |
| `MemorySpec$new()` | Create a memory specification |
| `validate_memory_field()` | Validate one memory-field record |
| `validate_memory_spec()` | Validate a memory specification |
| `validate_memory_proposal()` | Validate a memory-schema proposal |
| `memory_types()` | List supported memory types |
| `memory_persistence_policies()` | List supported memory persistence policies |
| `memory_schema_graph_data()` | Export graph-ready node and edge tables for a memory schema |
| `render_memory_schema_graphviz()` | Render a memory schema as Graphviz DOT, DiagrammeR, or SVG |
| `memory_action_methods()` | List constrained memory-schema message actions |

## Knowledge And Graph Helpers

| Function | Purpose |
| --- | --- |
| `validate_knowledge_item()` | Validate one narrative knowledge item |
| `validate_knowledge_spec()` | Validate a curated knowledge specification |
| `validate_knowledge_proposal()` | Validate a narrative-knowledge proposal |
| `knowledge_graph_node()` | Create a knowledge-graph node record |
| `knowledge_graph_edge()` | Create a knowledge-graph edge record |
| `new_knowledge_graph_spec()` | Build a knowledge-graph specification object |
| `add_knowledge_graph_node()` | Add a first-class graph-knowledge node |
| `add_knowledge_graph_edge()` | Add a first-class graph-knowledge edge |
| `validate_knowledge_graph_spec()` | Validate knowledge-graph structure |
| `knowledge_graph_from_spec()` | Build a projection graph from narrative `KnowledgeSpec` items |
| `knowledge_graph_data()` | Export graph-ready node and edge tables for a knowledge graph |
| `render_knowledge_graphviz()` | Render a knowledge graph as Graphviz DOT, DiagrammeR, or SVG |
| `plot_knowledge_graph()` | Plot a knowledge graph with DiagrammeR |
| `validate_knowledge_graph_proposal()` | Validate a graph-knowledge proposal |
| `knowledge_graph_action_methods()` | List constrained graph-knowledge message actions |

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

## Knowledge And Memory Bridge

| Function | Purpose |
| --- | --- |
| `knowledge_action_methods()` | List the knowledge actions an LLM may request |
| `build_knowledge_elicitation_prompt()` | Build a prompt to elicit raw domain knowledge |
| `build_knowledge_normalization_prompt()` | Build a prompt to normalize raw knowledge |
| `build_knowledge_conflict_check_prompt()` | Build a prompt to compare candidate knowledge against existing approved knowledge |
| `build_knowledge_design_prompt()` | Build a prompt focused on knowledge proposals and review |
| `build_memory_schema_prompt()` | Build a prompt for initial memory schema proposals |
| `build_memory_revision_prompt()` | Build a prompt for revising memory schema proposals |
| `build_knowledge_graph_extraction_prompt()` | Build a prompt for graph-knowledge extraction |
| `build_knowledge_graph_revision_prompt()` | Build a prompt for revising graph-knowledge proposals |
| `parse_knowledge_message()` | Parse constrained knowledge-action JSON |
| `preview_knowledge_message()` | Preview knowledge actions without mutating state |
| `apply_knowledge_message()` | Apply constrained knowledge actions to a knowledge-proposal state |
| `parse_memory_message()` | Parse constrained memory-schema action JSON |
| `preview_memory_message()` | Preview memory-schema actions without mutating state |
| `apply_memory_message()` | Apply constrained memory-schema actions to a memory-proposal state |
| `parse_knowledge_graph_message()` | Parse constrained graph-knowledge action JSON |
| `preview_knowledge_graph_message()` | Preview graph-knowledge actions without mutating state |
| `apply_knowledge_graph_message()` | Apply constrained graph-knowledge actions to a graph-proposal state |

## Design Review

| Function | Purpose |
| --- | --- |
| `build_design_review_data()` | Package the current design into a JS/HTML-ready review data bundle |
| `new_design_review_spec()` | Create a design-review data bundle directly |
| `validate_design_review_spec()` | Validate a design-review data bundle |
| `save_design_review_spec()` / `load_design_review_spec()` | Persist a design-review data bundle |
| `design_review_html()` / `export_design_review_html()` | Build or write a standalone offline review page |
| `design_feedback_item()` | Create a structured design-review feedback item |
| `validate_design_feedback()` | Validate one or more structured design-feedback items |
| `parse_design_feedback_json()` | Parse structured design feedback from JSON |
| `save_design_feedback()` / `load_design_feedback()` | Persist structured design feedback |
| `preview_design_feedback()` / `apply_design_feedback()` | Preview or route design feedback through scaffolder mechanisms |

## Workspace CLI

| Function | Purpose |
| --- | --- |
| `agentr_workspace_paths()` | Return standard workspace paths for lifecycle artifacts |
| `init_agentr_workspace()` | Create generic workspace directories for specs, states, prompts, reviews, traces, and responses |
| `init_agentr_proposal_states()` | Initialize workflow, memory, knowledge, and scaffolder proposal-state artifacts |
| `build_initial_spec_prompt()` | Write an initial manual-LLM prompt for workflow, agent, memory, or knowledge design |
| `build_revision_prompt()` | Write a revision prompt from current workspace state plus human feedback |
| `build_node_detail_prompt()` | Build a constrained prompt for one workflow node's schemas and nested workflow |
| `apply_initial_spec_message()` | Apply an initial constrained JSON response into workspace proposal state |
| `apply_revision_message()` | Apply a revision JSON response without implicitly approving specs |
| `apply_node_detail_message()` | Apply one node-detail response as a workflow proposal |
| `list_workspace_proposals()` | List workflow, agent, memory, or knowledge proposals in a workspace |
| `approve_workspace_proposal()` | Explicitly approve a workspace proposal and update approved artifacts |
| `reject_workspace_proposal()` | Reject a workspace proposal without mutating approved specs |
| `export_workspace_design_review()` | Export review HTML from workspace artifacts |
| `build_workspace_implementation_prompt()` | Write an implementation handoff prompt from approved workspace specs |

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
| `normalize_subsystem_key()` | Normalize legacy or mixed subsystem keys to canonical values |
| `save_memory_spec()` | Save a `MemorySpec` explicitly as RDS, JSON, or YAML |
| `save_memory_spec_json()` | Save a `MemorySpec` explicitly as JSON |
| `save_memory_spec_yaml()` | Save a `MemorySpec` explicitly as YAML |
| `load_memory_spec()` | Load a `MemorySpec` explicitly from RDS, JSON, or YAML |
| `load_memory_spec_json()` | Load a `MemorySpec` explicitly from JSON |
| `load_memory_spec_yaml()` | Load a `MemorySpec` explicitly from YAML |
| `save_knowledge_spec()` | Save a `KnowledgeSpec` explicitly as RDS, JSON, or YAML |
| `save_knowledge_spec_json()` | Save a `KnowledgeSpec` explicitly as JSON |
| `save_knowledge_spec_yaml()` | Save a `KnowledgeSpec` explicitly as YAML |
| `load_knowledge_spec()` | Load a `KnowledgeSpec` explicitly from RDS, JSON, or YAML |
| `load_knowledge_spec_json()` | Load a `KnowledgeSpec` explicitly from JSON |
| `load_knowledge_spec_yaml()` | Load a `KnowledgeSpec` explicitly from YAML |
| `save_knowledge_graph_spec()` | Save an `agentr_knowledge_graph_spec` explicitly as RDS, JSON, or YAML |
| `save_knowledge_graph_spec_json()` | Save an `agentr_knowledge_graph_spec` explicitly as JSON |
| `save_knowledge_graph_spec_yaml()` | Save an `agentr_knowledge_graph_spec` explicitly as YAML |
| `load_knowledge_graph_spec()` | Load an `agentr_knowledge_graph_spec` explicitly from RDS, JSON, or YAML |
| `load_knowledge_graph_spec_json()` | Load an `agentr_knowledge_graph_spec` explicitly from JSON |
| `load_knowledge_graph_spec_yaml()` | Load an `agentr_knowledge_graph_spec` explicitly from YAML |
| `save_knowledge_proposal()` | Save a `KnowledgeProposal` explicitly |
| `load_knowledge_proposal()` | Load a `KnowledgeProposal` explicitly |
| `load_agent()` | Load a supported `agentr` object |
| `backup_agent()` | Save a timestamped backup |
| `load_json_file()` | Load JSON files |
| `load_yaml_file()` | Load YAML files |
| `inferencer_available()` | Detect optional `inferencer` availability |
| `inferencer_integration()` | Build optional integration metadata |
| `create_decision_trace()` | Build a decision trace record |
| `append_decision_trace()` | Append a decision trace to JSONL or RDS storage |
| `read_decision_traces()` | Read stored decision traces |
| `create_reflection_trace()` | Build a reflection trace record |
| `append_reflection_trace()` | Append a reflection trace to JSONL or RDS storage |
| `read_reflection_traces()` | Read stored reflection traces |

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
