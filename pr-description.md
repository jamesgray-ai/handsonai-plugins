Hey @jamesgray007 👋

I ran your skills through `tessl skill review` at work and found some targeted improvements. Here's the full before/after:

| Skill | Before | After | Change |
|-------|--------|-------|--------|
| writing-vision-briefs | 74% | 93% | +19% |
| editing-hbr-articles | 94% | 99% | +5% |
| design | 74% | 77% | +3% |
| deconstruct | 81% | 81% | 0% |
| writing-workflow-sops | 87% | 87% | 0% |

![Score Card](score_card.png)

<details>
<summary>What changed</summary>

**writing-vision-briefs (+19%)**
- Expanded description with specific concrete actions (problem definition, target audience, key capabilities, success criteria, risks, scope breakdown) and natural trigger terms ("brainstorm a product idea", "explore a concept", "I have an idea", "what if we built")
- Removed coaching instructions the model already knows (tone guidelines, "be encouraging", "coach toward specificity")
- Trimmed verbose follow-up probe explanations and "if the user says X" scaffolding throughout the discovery phase
- Removed redundant helper text (stakeholder breakdown list, alternative exploration signal explanation, Q8 skip guidance)

**editing-hbr-articles (+5%)**
- Converted description from YAML chevron (`>`) to quoted string format
- Added explicit validation checkpoint (step 4) — re-read edited article against criteria checklist before finalizing

**design (+3%)**
- Converted description from YAML chevron (`>`) to quoted string format with explicit "Use when" trigger clause and natural terms ("plan workflow architecture", "automation blueprint")
- Extracted Outcome-Driven Processing Path (~60 lines) to `references/outcome-driven-path.md` to improve progressive disclosure — reduces main SKILL.md from 715 to 653 lines

**deconstruct (0% — description format fix)**
- Converted description from YAML chevron (`>`) to quoted string format
- Trimmed guidelines section: consolidated context probing guidance, removed redundant items the model already follows

**writing-workflow-sops (0% — structural cleanup)**
- Removed "Why lightweight?" explanatory paragraph (rationale doesn't need to be in the skill)
- Consolidated three interaction patterns (from artifacts, from tracker, from scratch) into a single table with shared core flow

</details>

I kept this PR focused on the 5 skills with the biggest improvement potential to keep the diff reviewable. Happy to follow up with the rest in a separate PR if you'd like.

Honest disclosure — I work at @tesslio where we build tooling around skills like these. Not a pitch - just saw room for improvement and wanted to contribute.

Want to self-improve your skills? Just point your agent (Claude Code, Codex, etc.) at [this Tessl guide](https://docs.tessl.io/evaluate/optimize-a-skill-using-best-practices) and ask it to optimize your skill. Ping me - [@yogesh-tessl](https://github.com/yogesh-tessl) - if you hit any snags.

Thanks in advance 🙏
