---
name: retrospective
description: Document a completed feature as a skill for future reference. Extracts decisions, failures, patterns from the conversation and git changes. Use after finishing work, saying "retrospective", "document this", or "save what we learned".
---

# retrospective

Turn a completed feature into searchable team knowledge.

## Workflow

### Step 1: Gather Context

Collect information from:

**From Git:**
```bash
# Recent commits on current branch
git log --oneline -10

# Files changed
git diff --name-only main...HEAD 2>/dev/null || git diff --name-only HEAD~5

# Stats
git diff --stat main...HEAD 2>/dev/null || git diff --stat HEAD~5
```

**From Conversation:**
- What was the goal?
- What approaches were tried?
- What failed and why?
- What decisions were made?
- What patterns emerged?

**From User (ask if unclear):**
- Feature name (kebab-case, e.g., `user-authentication`)
- Related PR number (if any)
- Any gotchas to warn future devs about?

### Step 2: Generate Feature Skill

Create the skill structure:

```
.claude/skills/features/<feature-name>/
└── SKILL.md
```

Use this template:

```markdown
---
name: <feature-name>
description: <One line describing the feature and when this skill is relevant>
---

# <Feature Name>

## Overview

| Item | Details |
|------|---------|
| **Date** | <YYYY-MM-DD> |
| **PR** | #<number> or N/A |
| **Goal** | <What we were trying to achieve> |
| **Files Changed** | <X files, +Y/-Z lines> |
| **Key Areas** | <paths or modules touched> |

## Decisions Made

| Decision | Why | Alternatives Considered |
|----------|-----|-------------------------|
| <Choice made> | <Reasoning> | <What else was considered> |

## Failed Attempts

| Attempt | Why it Failed | Lesson Learned |
|---------|---------------|----------------|
| <What was tried> | <Why it didn't work> | <Key insight> |

## Implementation

### Approach
<Brief description of the solution>

### Key Files
- `path/to/main/file.ts` - <what it does>
- `path/to/other/file.ts` - <what it does>

## Patterns Discovered

### <Pattern Name>
<Description of reusable pattern>

```<language>
// Example code if applicable
```

## Gotchas

- <Warning for future developers>
- <Edge case to remember>
- <Thing that's easy to forget>

## Related

- <Link to related features or docs>
- <External resources that helped>
```

### Step 3: Confirm with User

Present the generated skill:

```markdown
Here's the feature skill I've drafted:

---
[Show SKILL.md content]
---

Does this capture the key learnings? Anything to add or change?
```

### Step 4: Save the Skill

After user confirms:

```bash
# Create directory
mkdir -p .claude/skills/features/<feature-name>

# Write SKILL.md
# (use Write tool)
```

### Step 5: Suggest Next Steps

```markdown
Feature skill saved to `.claude/skills/features/<feature-name>/SKILL.md`

Next steps:
- [ ] Commit: `git add .claude/skills/features/<feature-name>`
- [ ] Include in PR or commit separately

Future developers can now use `/advise` to find this knowledge.
```

## Tips for Good Skills

1. **Be Specific** - "Used Redis for caching" not "added caching"
2. **Document Failures** - What didn't work is often more valuable than what did
3. **Include Numbers** - Config values, thresholds, limits
4. **Link to Code** - Reference actual file paths
5. **Warn About Gotchas** - Save future devs from your pain

## Trigger Phrases

- "retrospective"
- "document this feature"
- "save what we learned"
- "create feature skill"
- "wrap up this feature"
