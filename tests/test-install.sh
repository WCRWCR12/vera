#!/bin/bash
# Installer test: installs into a throwaway folder with its own fake home, so it never touches a real install.
#   bash tests/test-install.sh               (detected OS)
#   bash tests/test-install.sh --os mac      (Mac branch; runs on Git Bash too, for the file layout)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OSARG=""; [ "${1:-}" = "--os" ] && OSARG="--os ${2:-}"
T="$(mktemp -d "${TMPDIR:-/tmp}/vera-test.XXXXXX")"
H="$T/home"; mkdir -p "$H"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok    $*"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL  $*"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
inst() { bash "$REPO/setup/install.sh" --home "$H" $OSARG "$@"; }
tree_hash() { (cd "$1" && find . -type f ! -name '.vera-install.json' | LC_ALL=C sort | while read -r f; do cksum "$f"; done) | cksum; }

echo "Install test in $T ($([ -n "$OSARG" ] && echo "$OSARG" || echo detected OS))"

out="$(inst --name "Sam" --tz "Australia/Sydney" --dry-run)"; rc=$?
check "dry run exits 0" '[ $rc = 0 ]'
check "dry run says so" 'printf "%s" "$out" | grep -q "^\[dry run\] added"'
check "dry run writes nothing" '[ ! -e "$H/Vera" ] && [ ! -e "$H/.claude" ]'

out="$(inst --name "Sam" --tz "Australia/Sydney")"; rc=$?
check "install exits 0" '[ $rc = 0 ]'
check "install reports RESULT" 'printf "%s" "$out" | grep -q "^RESULT added=[1-9]"'
V="$H/Vera"
check "CLAUDE.md personalised" 'grep -q "Sam" "$V/CLAUDE.md" && grep -q "Australia/Sydney" "$V/CLAUDE.md"'
check "no install {{placeholders}} left" '! grep -rlF -e "{{OWNER_NAME}}" -e "{{ASSISTANT_NAME}}" -e "{{TIMEZONE}}" -e "{{TODAY" "$V" "$H/.claude" >/dev/null'
check "skills installed" '[ -f "$H/.claude/skills/morning-brief/SKILL.md" ] && [ -f "$H/.claude/skills/evening-wrap/SKILL.md" ]'
check "desk settings present" '[ -f "$V/.claude/settings.json" ] && grep -q disableBypassPermissionsMode "$V/.claude/settings.json"'
check "telegram settings present" '[ -f "$V/vera-settings.json" ]'
check "agents present" '[ -f "$V/.claude/agents/scout.md" ] && grep -q "disallowedTools" "$V/.claude/agents/scout.md"'
check "inbox and workflows made" '[ -d "$V/inbox" ] && [ -d "$V/workflows" ]'
check "install record written" 'grep -q "\"name\": \"Sam\"" "$V/.vera-install.json"'
if printf '%s' "$out" | grep -q "os=windows"; then
  check "windows launchers only" '[ -f "$V/start-vera.cmd" ] && [ -f "$V/start-screen.cmd" ] && [ -f "$V/tools/set-telegram-token.ps1" ] && [ ! -e "$V/start-vera.command" ]'
  check ".cmd has CRLF line endings" 'head -1 "$V/start-vera.cmd" | od -c | grep -q "\\\\r"'
  check "launcher personalised" 'grep -q "Vera on Telegram" "$V/start-vera.cmd"'
else
  check "mac launchers only" '[ -f "$V/start-vera.command" ] && [ -f "$V/start-screen.command" ] && [ -f "$V/tools/set-telegram-token.command" ] && [ ! -e "$V/start-vera.cmd" ]'
  check ".command has LF line endings" '! head -1 "$V/start-vera.command" | od -c | grep -q "\\\\r"'
fi
check "settings read-only on disk" '[ ! -w "$V/.claude/settings.json" ] && [ ! -w "$V/vera-settings.json" ]'
check "nothing set to start at login" '[ ! -e "$H/Library/LaunchAgents" ] && [ ! -e "$H/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup" ]'

h1="$(tree_hash "$H")"
out="$(inst)"; rc=$?
check "second run exits 0, reuses saved details" '[ $rc = 0 ]'
check "second run adds/updates nothing" 'printf "%s" "$out" | grep -q "RESULT added=0 updated=0 "'
check "second run leaves tree byte-identical" '[ "$(tree_hash "$H")" = "$h1" ]'

# The person's data survives; an edited Vera file is kept without --update and backed up with it.
printf '| 9 | Pick up dry cleaning | 2026-11-01 | open | 0 | |\n' >> "$V/tasks.md"
chmod u+w "$V/protocols/nag.md"; printf '\nMy own edit.\n' >> "$V/protocols/nag.md"
out="$(inst)"
check "user's task row survives" 'grep -q "Pick up dry cleaning" "$V/tasks.md"'
check "edited Vera file kept and reported" 'grep -q "My own edit." "$V/protocols/nag.md" && printf "%s" "$out" | grep -q "protocols/nag.md"'
out="$(inst --update)"
check "--update refreshes the edited file" '! grep -q "My own edit." "$V/protocols/nag.md"'
check "--update backs up the old copy" 'grep -rq "My own edit." "$V/.backups"'
check "--update still keeps user data" 'grep -q "Pick up dry cleaning" "$V/tasks.md"'
check "--update writes read-only settings" 'printf "%s" "$out" | grep -q "RESULT" && [ -f "$V/vera-settings.json" ]'

out="$(inst --name 'Bad"Name')"; rc=$?
check "rejects a name with quotes" '[ $rc = 2 ]'
out="$(inst --tz 'Not a zone; rm')"; rc=$?
check "rejects a bad time zone" '[ $rc = 2 ]'

out="$(inst --uninstall --dry-run)"
check "uninstall dry run keeps folder" '[ -d "$V" ]'
out="$(inst --uninstall)"
check "uninstall moves the folder (not deleted)" '[ ! -e "$V" ] && ls -d "$H"/Vera-removed-* "$H"/.Trash/Vera-* 2>/dev/null | grep -q .'
check "uninstall moves Vera's skills" '[ ! -e "$H/.claude/skills/morning-brief" ]'

# A developer copy with a screen key, caches or local state must not ship them.
mkdir -p "$T/repo"; (cd "$REPO" && tar cf - --exclude=.git .) | (cd "$T/repo" && tar xf -)
printf 'not-a-real-key-not-a-real-key-not-a-real-key\n' > "$T/repo/vera/screen/.token"
mkdir -p "$T/repo/vera/screen/__pycache__" "$T/repo/vera/screen/backups"; : > "$T/repo/vera/screen/__pycache__/x.pyc"
printf '{}\n' > "$T/repo/vera/screen/data/state.json"
bash "$T/repo/setup/install.sh" --home "$T/home2" --name Sam $OSARG >/dev/null
check "dev-copy key, caches and state are not installed" '[ -d "$T/home2/Vera/screen" ] && [ ! -e "$T/home2/Vera/screen/.token" ] && [ ! -e "$T/home2/Vera/screen/__pycache__" ] && [ ! -e "$T/home2/Vera/screen/data/state.json" ] && [ ! -e "$T/home2/Vera/screen/backups" ]'

echo "Result: $PASS passed, $FAIL failed"
chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"
[ "$FAIL" = 0 ]
