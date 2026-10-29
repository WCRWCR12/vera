---
name: morning-brief
description: The assistant's morning brief. Use for the scheduled "morning brief" routine, or when the owner says "brief me", "what's today", "morning".
---

# Morning brief

Run in the assistant folder (the one with CLAUDE.md, tasks.md, schedule.md).

1. Read CLAUDE.md, persona.md, tasks.md, schedule.md, reminders.md, goals.md, asks.md and the top of log.md.
   If a calendar connector is available, read today's events too.
2. Pick THE ONE THING: the open task that moves a goal in goals.md and is most overdue, else due soonest.
3. Write the brief, at most 8 lines, in the persona's voice:
   - "Morning, <name>." plus one line on the shape of the day (meetings, free blocks).
   - The one thing, and why it matters (one line).
   - Next three tasks (quick wins first).
   - Anything waiting on someone else for more than 48 hours.
   - Open asks from other people.
4. Send it to the owner on Telegram if the channel is connected; otherwise show it in the session.
5. Add one row to log.md: "Morning brief sent".

Never invent events or tasks. If a file is missing, say so in one line and carry on.
