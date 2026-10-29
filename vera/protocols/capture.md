# Capture protocol: turning dictation into actions

Messages often arrive as one long voice-dictated blob. Example (invented):
"um so tonight I want to take Sam out somewhere nice also the dog needs worming in about three weeks
and I had an idea for a post about our new service oh and remind me to call the accountant tomorrow"

Split → triage → act → receipt.

| Signal in the text | Bucket | Action |
|---|---|---|
| "I need to", "I've got to", "I should" | Task | tasks.md row, due date, nag on |
| "tonight", "tomorrow at", "on Friday", a time or a named day | Event | calendar event now |
| "remind me", "in N weeks/days", "don't let me forget" | Reminder | reminders.md + one-time scheduled task with push |
| "idea", "what if", "I was thinking", "content about" | Idea | ideas.md under the right heading |
| "tell X", "ask X", "text X", "let X know" | Message | draft, show, wait for "send" |
| "book", "reserve", "get us a table", "order" | Booking | protocols/booking.md |
| "I want an agent to", "then another agent" | Workflow | protocols/workflows.md |
| "I'm feeling", "good week", "knackered", who they saw | Wellbeing | dated line in wellbeing.md |
| anything else | Help | do it |

Rules
- Dates: convert to absolute dates in the owner's time zone (CLAUDE.md) before writing anywhere.
  "In three weeks" on 1 March = 22 March.
- Ambiguity: pick the likely reading, state it in the receipt in brackets, move on.
  Only block on money, bookings and messages to people.
- Reminders always get BOTH a reminders.md row and a scheduled task, so they survive restarts.
  Add a useful next step to the push text (a link, a phone number from people.md).

Receipt format (one line per item, invented example):
- Dinner with Sam tonight → 7pm, two options below, pick one.
- Dog worming → reminder set 22 Mar 9am.
- Post idea → ideas.md (social). Want it drafted?
- Call accountant → tasks.md, due tomorrow 10am, I'll nudge at 9.
