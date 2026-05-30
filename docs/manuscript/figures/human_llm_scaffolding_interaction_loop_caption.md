Figure 6. Human--LLM scaffolding interaction loop.

The diagram shows the audit-oriented manual-LLM loop in which `agentr` writes
initial or revision prompts into a workspace, an external model returns JSON
actions, those actions are validated and applied into proposal state, and
standalone review HTML returns structured human feedback into the next round.
Approved specs remain unchanged until explicit approval.
