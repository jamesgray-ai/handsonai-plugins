# Outcome-Driven Processing Path

When the Workflow Definition has `Definition Type: Outcome-Driven`, the following modifications apply to the standard workflow:

**Step 3 (Architecture Decisions):** Same as standard — extract tools from the Capability Domains and Tools/Data sections instead of from step data flows.

**Step 4 (Autonomy Assessment):** State as fact: "This is an outcome-driven workflow — autonomy is **Autonomous** by definition. The agent system determines its own execution path."

**Step 5 (Orchestration Mechanism):** State as fact: "Orchestration is **Agent**." Still determine the involvement mode (Augmented/Automated) from the definition's Human Gates section and trigger type. Still ask the platform sub-choice if the platform has multiple agent offerings.

**Step 6 (Classify Each Step) → Capability Domain Mapping:** Replace per-step classification with capability domain mapping. For each capability domain from the definition:

| Domain | Integration Needs | Intelligence Requirements | Reusable Skill? |
|--------|-------------------|--------------------------|-----------------|
| [domain] | Tools/connectors needed | Model class, context sources | Yes/No + rationale |

Same Integration Discovery and Skill Discovery processes apply, operating on capability domains instead of steps.

**Step 7 (Skill Candidates):** Same — identify which capability domains should become skills.

**Step 8 (Agent Configuration):** This becomes the primary section. Agent Configuration is mandatory for outcome-driven definitions. Document the agent(s) with all standard fields, drawing instructions from the definition's Goal, Constraints, and Expected Outputs.

**Step 8b (Evaluation Criteria):** Carry forward from the definition's Quality Criteria — see above.

**Step 9 (Generate Spec):** Use the modified template sections below. The spec uses the same filename pattern. Conditional sections replace Step-by-Step Decomposition with Capability Domain Mapping, and Autonomy Spectrum Summary with a brief Autonomous statement.

**Outcome-driven spec template modifications:**

Replace the `## Step-by-Step Decomposition` section with:

```markdown
## Capability Domain Mapping

| Domain | Description | Integration (use/build) | Intelligence | Reusable Skill? |
|--------|-------------|------------------------|--------------|-----------------|

### Autonomy Statement

This is an outcome-driven workflow. Autonomy is Autonomous — the agent system determines its own execution path based on the goal, inputs, and constraints.
```

Replace the `## Skill Candidates` section header with capability-domain-based skill candidates (same field structure, keyed by domain instead of step number).

The `## Agent Configuration` section is **mandatory** (not optional) for outcome-driven specs.

All other spec sections remain the same, except **Step Sequence and Dependencies** is omitted for outcome-driven specs — the agent determines its own execution path, so there is no fixed step sequence to document.

**Build Skill Needs Checklist modifications for outcome-driven:**
- [ ] `Architecture Decisions` table has Platform, Platform Mode, Orchestration (Agent), and Involvement rows
- [ ] Capability Domain Mapping table is present with Integration and Intelligence columns
- [ ] Every Integration column entry includes block type, tool name, and use/build tag
- [ ] Every skill candidate has all 8 fields: Purpose, Covers Steps / Domains, Inputs, Outputs, Decision Logic, Failure Modes, Required Tools, Depends On
- [ ] Every "Exists" item in Context Inventory has a Location value
- [ ] Every tool in the Integration column has a matching entry in Integration Options with at least one Source URL
- [ ] Model Recommendation section is present with a default class
- [ ] Data Readiness Summary is present (even if "all accessible")
- [ ] Agent Configuration is present with Skills and Trigger Examples fields
- [ ] Evaluation Criteria section is present with at least 3 test scenarios
- [ ] Quality criteria carried forward from Workflow Definition
