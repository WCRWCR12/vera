#!/bin/bash
# Docs check: every relative link in the guides resolves, and every repository file the guides name exists.
#   bash tests/check-docs.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 1
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $*"; }

# 1. Markdown links [text](target) that are not web links must exist (relative to the file).
for doc in README.md CLAUDE-SETUP.md CLAUDE.md SECURITY.md OPEN-ITEMS.md legal/*.md vera/*.md vera/protocols/*.md; do
  [ -f "$doc" ] || { bad "missing doc $doc"; continue; }
  dir="$(dirname "$doc")"
  while IFS= read -r target; do
    case "$target" in http://*|https://*|mailto:*|\#*|"") continue ;; esac
    t="${target%%#*}"
    if [ -e "$dir/$t" ]; then ok; else bad "$doc links to $target (not found)"; fi
  done <<EOF
$(grep -oE '\]\([^)]+\)' "$doc" | sed -E 's/^\]\(//; s/\)$//')
EOF
done

# 2. Repository files and folders the guides and the installer depend on.
for f in README.md CLAUDE-SETUP.md CLAUDE.md SECURITY.md OPEN-ITEMS.md LICENSE VERSION .gitattributes \
         setup/install.sh legal/TERMS.md legal/PRIVACY.md legal/README.md \
         vera/CLAUDE.md vera/persona.md vera/personas/chief-of-staff.md vera/personas/coach.md vera/personas/calm-organiser.md \
         vera/protocols/nag.md vera/protocols/capture.md vera/protocols/circles.md vera/protocols/messaging.md \
         vera/protocols/booking.md vera/protocols/workflows.md vera/.claude/settings.json vera/vera-settings.json \
         vera/.claude/agents/scout.md vera/.claude/agents/analyst.md vera/.claude/agents/booker.md vera/.claude/agents/maker.md \
         vera/screen/server.py vera/screen/web/index.html vera/screen/web/app.js vera/screen/data/onlyyou.json \
         vera/tasks.md vera/people.md vera/preferences.md vera/schedule.md vera/log.md vera/goals.md vera/reminders.md \
         vera/asks.md vera/ideas.md vera/wellbeing.md \
         skills/morning-brief/SKILL.md skills/evening-wrap/SKILL.md \
         launchers/windows/start-vera.cmd launchers/windows/start-screen.cmd launchers/windows/tools/set-telegram-token.ps1 \
         launchers/mac/start-vera.command launchers/mac/start-screen.command launchers/mac/tools/set-telegram-token.command; do
  if [ -e "$f" ]; then ok; else bad "named in the guides but missing: $f"; fi
done

# 3. The files CLAUDE-SETUP.md tells Claude to run inside the installed Vera folder come from the launchers.
for n in start-vera start-screen; do
  grep -q "Vera/$n.cmd" CLAUDE-SETUP.md && { [ -f "launchers/windows/$n.cmd" ] && ok || bad "$n.cmd"; }
  grep -q "Vera/$n.command" CLAUDE-SETUP.md && { [ -f "launchers/mac/$n.command" ] && ok || bad "$n.command"; }
done
grep -q 'Vera/tools/set-telegram-token.ps1' CLAUDE-SETUP.md && ok || bad "token helper (Windows) not referenced"
grep -q 'Vera/tools/set-telegram-token.command' CLAUDE-SETUP.md && ok || bad "token helper (Mac) not referenced"

# 4. Only one human guide and one Claude guide: no leftover guides from older packages.
for old in START-HERE.md SETUP.md SET-ME-UP.md SETUP.html INSTALL.md TELEGRAM.md telegram/TELEGRAM.md; do
  if [ -e "$old" ]; then bad "old guide still present: $old"; else ok; fi
done

# 5. The human guide never tells the person to type a command into a terminal.
RX='open (the )?terminal|in terminal:|cd ~/|brew install|/plugin install|/telegram:access'
if grep -iE "$RX" README.md | grep -viE 'never open terminal' | grep -q .; then
  bad "README.md asks the person to use a terminal or slash command:"; grep -niE "$RX" README.md
else ok; fi

# 6. Every JSON file parses (python if present, else skip).
PY=""
for c in python3 python; do   # skip the Windows Store stub, which only prints an install hint
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys' >/dev/null 2>&1; then PY="$(command -v "$c")"; break; fi
done
if [ -n "$PY" ]; then
  for j in $(find . -path ./.git -prune -o -name '*.json' -print); do
    if "$PY" -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$j" 2>/dev/null; then ok; else bad "invalid JSON: $j"; fi
  done
fi

# 7. Shell scripts parse.
for s in setup/install.sh tests/*.sh launchers/mac/*.command launchers/mac/tools/*.command; do
  if bash -n "$s"; then ok; else bad "bash syntax error: $s"; fi
done

echo "Docs check: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
