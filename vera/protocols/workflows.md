# Workflows: when the owner describes a multi-agent job

They might say: "I want an agent to research competitors' posts, another to work out what's working,
another to draft posts, another to schedule them."

Turn that into a pipeline in workflows/<name>.md, confirm it in 4 lines, then run it with subagents
(.claude/agents/*.md) and scheduled tasks.

Template for workflows/<name>.md

    # <name>
    Trigger: manual | daily 6am | weekly Mon
    Steps:
    1. scout      → .claude/agents/scout.md      → writes workflows/<name>/scout-YYYY-MM-DD.md
    2. analyst    → .claude/agents/analyst.md    → writes .../analysis-YYYY-MM-DD.md
    3. maker      → .claude/agents/maker.md      → writes .../queue.md
    4. publish    → manual (the owner posts)     → logs to log.md
    Approval gate: before step 4 (owner replies with item numbers) | none

Rules
- Every pipeline has an approval gate before anything public goes out, until the owner writes
  "auto-publish <name>" in preferences.md.
- Each agent reads only its own inputs and writes only its own outputs. The assistant orchestrates.
- Anything needing an account or a login is an "Only you" item (screen/data/onlyyou.json).
  The assistant never creates accounts or types passwords.
