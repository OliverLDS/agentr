# Table 5. Proposal States And Transition Rules

Caption: Proposal states and transition rules.

## Workflow proposals

| State | Meaning | Typical transition in | Typical transition out |
|---|---|---|---|
| `pending` | A newly created workflow proposal awaiting review. | Created by preview or proposal creation. | Moves to `under_discussion`, `approved`, or `rejected`. |
| `under_discussion` | A workflow proposal being actively reviewed or revised. | Entered from `pending` after discussion begins. | Moves to `approved` or `rejected`. |
| `approved` | A workflow proposal accepted as the live approved workflow. | Entered from `pending` or `under_discussion` by approval. | May later become `superseded` if a newer proposal is approved. |
| `superseded` | A previously approved or still-active proposal displaced by a newer approved proposal. | Entered when a newer workflow proposal is approved. | Typically terminal. |
| `rejected` | A workflow proposal not accepted for promotion. | Entered from `pending` or `under_discussion` by rejection. | Typically terminal. |

## Agent-spec proposals

| State | Meaning | Typical transition in | Typical transition out |
|---|---|---|---|
| `draft` | A newly created agent-spec proposal awaiting review. | Created by `propose_agent_spec()`. | Moves to `under_discussion`, `approved`, or `rejected`. |
| `under_discussion` | An agent-spec proposal under active review or revision. | Entered from `draft` after discussion begins. | Moves to `approved` or `rejected`. |
| `approved` | An agent-spec proposal accepted as the live approved agent design. | Entered from `draft` or `under_discussion` by approval. | May later become `superseded` if a newer proposal is approved. |
| `superseded` | A previously approved or still-active agent-spec proposal displaced by a newer approved proposal. | Entered when a newer agent-spec proposal is approved. | Typically terminal. |
| `rejected` | An agent-spec proposal not accepted for promotion. | Entered from `draft` or `under_discussion` by rejection. | Typically terminal. |
