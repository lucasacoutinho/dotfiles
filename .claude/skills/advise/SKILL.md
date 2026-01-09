---
name: advise
description: Search project knowledge before starting a feature. Finds relevant past implementations, decisions, failures, and patterns. Use when starting new work, saying "advise", "what do we know about", or "before I start".
---

# advise

Search your project's feature knowledge before starting new work.

## Workflow

### Step 1: Understand the Goal

Ask the user (if not clear):
- What feature/bugfix/refactor are you starting?
- What area of the codebase does this touch?

### Step 2: Search Feature Skills

Look in `.claude/skills/features/` for relevant past work:

```bash
# Find all feature skills
find .claude/skills/features -name "SKILL.md" 2>/dev/null

# Search by keyword in skill content
grep -r "authentication\|auth\|login" .claude/skills/features/ 2>/dev/null
```

Also check:
- `.claude/skills/patterns/` - reusable patterns
- `.claude/skills/gotchas/` - known pitfalls
- `CLAUDE.md` - project-level guidance

### Step 3: Read and Synthesize

For each relevant skill found, extract:

| Section | What to Surface |
|---------|-----------------|
| **Decisions Made** | Why past choices were made, alternatives rejected |
| **Failed Attempts** | What NOT to do and why |
| **Patterns Discovered** | Reusable code/approaches |
| **Gotchas** | Warnings and edge cases |
| **Files Changed** | Where similar work was done |

### Step 4: Present Findings

Format your response as:

```markdown
## Relevant Past Work

### [Feature Name] (PR #123, 2026-01-05)
**Relevance:** [Why this matters for current task]

**Key Decisions:**
- [Decision]: [Why]

**Watch Out For:**
- [Gotcha from past work]

**Patterns to Reuse:**
- [Pattern]: See `path/to/file.ts`

---

### [Another Feature]
...

## Recommendations

Based on past work, I suggest:
1. [Approach recommendation]
2. [Pattern to follow]
3. [Thing to avoid]
```

### Step 5: Offer to Continue

Ask:
> "Ready to start implementing? I can help you plan the approach based on these patterns."

## If No Skills Found

If `.claude/skills/features/` is empty or doesn't exist:

```markdown
No feature skills found yet. This appears to be a new knowledge base.

After completing this feature, use `/retrospective` to document:
- Decisions made and why
- Failed approaches
- Patterns discovered
- Gotchas for future reference

This builds your project's institutional knowledge over time.
```

## Trigger Phrases

- "advise"
- "what do we know about X"
- "before I start"
- "any prior work on"
- "search for similar features"
