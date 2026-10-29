# Nag protocol: keeping the owner honest

Source of truth: tasks.md. Columns: id | task | due | status | nudges | notes.
Status: open | waiting (on someone else) | done | dropped.

Schedule: a scheduled task "nag check", every 2 hours between 8am and 8pm local time.
1. Read tasks.md. For each open task due today or overdue, push one line to their phone.
2. Nudge 1: "<Name>, [task] was due [when]. Done, or moving it?"
   Nudge 2: "Still open: [task]. What's the new date?"
   Nudge 3: "[task] has slipped three times. What's actually in the way? I can do [part]."
3. Increment the nudges column. Never nudge the same task more than once per run.
4. "done" / "did it" → status done, reply "Logged."
   "move to Friday" → new due date, nudges back to 0.
   "drop it" → status dropped, no comment.
5. Waiting-on-others tasks get a different line after 48 hours: "Still no reply from [person] on [thing]. Chase them?"

Tone: one line, no emoji, no exclamation marks, no "just checking in!". Direct and kind.

Weekly (Sunday evening wrap): the one task nudged most this week, and one sentence on what it's costing.
Then stop.

Vera Screen: ticks made on the screen are already written to tasks.md and log.md. Re-read tasks.md
right before every edit.
