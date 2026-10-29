#!/bin/bash
# Vera installer for Windows (run by Claude through Git Bash) and Mac. Claude runs this while following
# CLAUDE-SETUP.md; the person never types it.
#
#   bash setup/install.sh --name "Sam" --tz "Australia/Sydney" --dry-run     preview, writes nothing
#   bash setup/install.sh --name "Sam" --tz "Australia/Sydney"               install
#   bash setup/install.sh --update        refresh Vera's own files (old copies backed up); notes never touched
#   bash setup/install.sh --uninstall     move the Vera folder and Vera's skills out of the way (not deleted)
#
# Options: --assistant <name> (default Vera)  --dir <folder> (default ~/Vera)  --home <folder> (tests only)
#          --os windows|mac (default: detected)
#
# Rules (never broken):
#  - Your notes (tasks, people, preferences, persona, screen data) are created only when missing. Never overwritten.
#  - Vera's own files are added when missing. Without --update an existing copy is left alone and reported.
#    With --update the old copy is backed up to <Vera folder>/.backups/<date-time>/ first.
#  - Running the same install twice changes nothing the second time.
#  - Nothing is set to start at login: no LaunchAgent, Login Item, scheduled task or Startup shortcut.
# Works with the bash 3.2 that ships with macOS.
set -u
umask 077

NAME=""; ASSISTANT=""; TZONE=""; DIR=""; HOMEDIR="$HOME"; OS=""; DRY=0; UPDATE=0; UNINSTALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2 ;;
    --assistant) ASSISTANT="${2:-}"; shift 2 ;;
    --tz) TZONE="${2:-}"; shift 2 ;;
    --dir) DIR="${2:-}"; shift 2 ;;
    --home) HOMEDIR="${2:-}"; shift 2 ;;
    --os) OS="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --update) UPDATE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    *) echo "ERROR: unknown option $1"; exit 2 ;;
  esac
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
if [ -z "$OS" ]; then
  case "$(uname -s)" in
    Darwin) OS=mac ;;
    MINGW*|MSYS*|CYGWIN*) OS=windows ;;
    *) echo "ERROR: this installer supports Windows (Git Bash) and Mac only."; exit 2 ;;
  esac
fi
case "$OS" in windows|mac) ;; *) echo "ERROR: --os must be windows or mac"; exit 2 ;; esac
[ -n "$DIR" ] || DIR="$HOMEDIR/Vera"
SKILLS="$HOMEDIR/.claude/skills"
RECORD="$DIR/.vera-install.json"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DIR/.backups/$STAMP"
P=""; [ "$DRY" = 1 ] && P="[dry run] "
say() { printf '%s%s\n' "$P" "$*"; }

# ------------------------------------------------------------------ uninstall
if [ "$UNINSTALL" = 1 ]; then
  if [ "$OS" = mac ]; then DEST="$HOMEDIR/.Trash/Vera-$STAMP"; else DEST="$HOMEDIR/Vera-removed-$STAMP"; fi
  if [ -d "$DIR" ]; then
    say "Moving $DIR to $DEST (nothing is deleted; you can still get your notes back)."
    if [ "$DRY" = 0 ]; then mkdir -p "$(dirname "$DEST")"; chmod -R u+w "$DIR"; mv "$DIR" "$DEST"; fi
  else
    say "No Vera folder at $DIR."
  fi
  for s in "$REPO"/skills/*/; do
    n="$(basename "$s")"
    if [ -d "$SKILLS/$n" ]; then
      say "Moving skill $n to $DEST-skills/$n"
      if [ "$DRY" = 0 ]; then mkdir -p "$DEST-skills"; mv "$SKILLS/$n" "$DEST-skills/$n"; fi
    fi
  done
  say "Not touched: the Telegram plugin and its token file. To stop the bot for good, send /revoke to @BotFather."
  echo "RESULT uninstall done dest=$DEST"
  exit 0
fi

# ------------------------------------------------------------------ details
jget() { # jget KEY : read a string value from the install record (simple flat JSON written below)
  [ -f "$RECORD" ] || return 0
  sed -n "s/^ *\"$1\": *\"\\(.*\\)\",\\{0,1\\}$/\\1/p" "$RECORD" | head -1
}
[ -n "$NAME" ] || NAME="$(jget name)"
[ -n "$ASSISTANT" ] || ASSISTANT="$(jget assistant)"
[ -n "$TZONE" ] || TZONE="$(jget timezone)"
[ -n "$ASSISTANT" ] || ASSISTANT="Vera"
if [ -z "$TZONE" ] && [ "$OS" = mac ]; then TZONE="$(readlink /etc/localtime 2>/dev/null | sed 's#.*zoneinfo/##')"; fi
[ -n "$TZONE" ] || TZONE="UTC"
if [ -z "$NAME" ]; then echo "ERROR: pass --name with the person's first name."; exit 2; fi
check_name() { # letters (any language), numbers, spaces, dots, hyphens, apostrophes; 1-40 characters
  local v="$2"
  if [ -z "$v" ] || [ "${#v}" -gt 40 ] || printf '%s' "$v" | LC_ALL=C grep -q '[][\\/"`$<>|&;%^{}()*?!=#~:@+,[:cntrl:]]'; then
    echo "ERROR: $1 may only use letters, numbers, spaces, dots, hyphens and apostrophes (40 at most)."; exit 2
  fi
}
check_name "--name" "$NAME"; check_name "--assistant" "$ASSISTANT"
if ! printf '%s' "$TZONE" | grep -Eq '^[A-Za-z_]+(/[A-Za-z0-9_+-]+){0,2}$'; then
  echo "ERROR: --tz must look like Australia/Sydney or Europe/Paris."; exit 2
fi
TODAY="$(date +%Y-%m-%d)"
if date -v+3d +%Y-%m-%d >/dev/null 2>&1; then TODAY3="$(date -v+3d +%Y-%m-%d)"; else TODAY3="$(date -d '+3 days' +%Y-%m-%d)"; fi

DATA_FILES=" tasks.md people.md preferences.md reminders.md asks.md ideas.md goals.md schedule.md log.md wellbeing.md persona.md screen/data/habits.json screen/data/onlyyou.json screen/data/screen.json "
if [ "$OS" = windows ]; then
  LAUNCH="$REPO/launchers/windows"
  LOCK_FILES=".claude/settings.json vera-settings.json start-vera.cmd start-screen.cmd tools/set-telegram-token.ps1"
else
  LAUNCH="$REPO/launchers/mac"
  LOCK_FILES=".claude/settings.json vera-settings.json start-vera.command start-screen.command tools/set-telegram-token.command"
fi

# ------------------------------------------------------------------ copy engine
ADDED=0; UPDATED=0; UNCHANGED=0; KEPT=0; DIFFERS=0; DIFF_LIST=""
WORK="$(mktemp -d "${TMPDIR:-/tmp}/vera-install.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

render() { # render SRC OUT : fill the {{...}} details into text files; .cmd files get Windows line endings
  case "$1" in
    *.md|*.json|*.cmd|*.ps1|*.command|*.sh)
      V_OWNER="$NAME" V_ASSIST="$ASSISTANT" V_TZ="$TZONE" V_TODAY="$TODAY" V_TODAY3="$TODAY3" perl -pe '
        s/\{\{OWNER_NAME\}\}/$ENV{V_OWNER}/g; s/\{\{ASSISTANT_NAME\}\}/$ENV{V_ASSIST}/g; s/\{\{TIMEZONE\}\}/$ENV{V_TZ}/g;
        s/\{\{TODAY\+3\}\}/$ENV{V_TODAY3}/g; s/\{\{TODAY\}\}/$ENV{V_TODAY}/g;' "$1" > "$2" ;;
    *) cp "$1" "$2" ;;
  esac
  case "$1" in *.cmd|*.ps1) perl -pi -e 's/\r?\n/\r\n/' "$2" ;; esac
}

put() { # put SRC DST REL IS_DATA
  local src="$1" dst="$2" rel="$3" isdata="$4" tmp="$WORK/new"
  render "$src" "$tmp"
  if [ ! -e "$dst" ]; then
    say "added   $rel"; ADDED=$((ADDED+1))
    if [ "$DRY" = 0 ]; then mkdir -p "$(dirname "$dst")"; cp "$tmp" "$dst"; fi
    return
  fi
  if [ "$isdata" = 1 ]; then KEPT=$((KEPT+1)); return; fi
  if cmp -s "$tmp" "$dst"; then UNCHANGED=$((UNCHANGED+1)); return; fi
  if [ "$UPDATE" = 0 ]; then DIFFERS=$((DIFFERS+1)); DIFF_LIST="$DIFF_LIST
  $rel"; return; fi
  say "updated $rel (old copy backed up)"; UPDATED=$((UPDATED+1))
  if [ "$DRY" = 0 ]; then
    mkdir -p "$(dirname "$BACKUP/$rel")"; cp -p "$dst" "$BACKUP/$rel"
    chmod u+w "$dst"; cp "$tmp" "$dst"
  fi
}

list_files() { # every file to ship, skipping caches, local state and any screen key left in a dev copy
  find "$1" \( -name __pycache__ -o -name backups -o -name .backups \) -prune -o \
    -type f ! -name .token ! -name state.json ! -name '*.pyc' ! -name .DS_Store -print | LC_ALL=C sort
}

put_tree() { # put_tree SRC_ROOT DST_ROOT LABEL DATA_AWARE
  local root="$1" dst="$2" label="$3" aware="$4" f rel isdata
  while IFS= read -r f; do
    rel="${f#$root/}"
    isdata=0
    if [ "$aware" = 1 ]; then case "$DATA_FILES" in *" $rel "*) isdata=1 ;; esac; fi
    put "$f" "$dst/$rel" "$label$rel" "$isdata"
  done <<EOF
$(list_files "$root")
EOF
}

echo "------------------------------------------------------------"
say "Installing $ASSISTANT for $NAME into $DIR ($OS)"
echo "------------------------------------------------------------"
put_tree "$REPO/vera" "$DIR" "" 1
put_tree "$LAUNCH" "$DIR" "" 1
for f in SECURITY.md VERSION LICENSE; do put "$REPO/$f" "$DIR/$f" "$f" 0; done
for s in "$REPO"/skills/*/; do
  n="$(basename "$s")"
  put_tree "${s%/}" "$SKILLS/$n" "skills/$n/" 0
done
for d in inbox workflows; do
  if [ ! -d "$DIR/$d" ]; then say "added   $d/"; [ "$DRY" = 0 ] && mkdir -p "$DIR/$d"; fi
done

if [ "$DRY" = 0 ]; then
  # Launchers can be double-clicked; Vera's safety settings and launchers are read-only on disk
  # (her settings also deny editing them). On Mac, personal notes are readable by this user only.
  if [ "$OS" = mac ]; then
    chmod 755 "$DIR"/*.command "$DIR"/tools/*.command 2>/dev/null
    xattr -d com.apple.quarantine "$DIR"/*.command "$DIR"/tools/*.command 2>/dev/null
    chmod -R go-rwx "$DIR" 2>/dev/null
  fi
  for rel in $LOCK_FILES; do [ -e "$DIR/$rel" ] && chmod a-w "$DIR/$rel"; done
  VERSION="$(head -1 "$REPO/VERSION" | tr -d '\r')"
  [ -e "$RECORD" ] && chmod u+w "$RECORD"
  cat > "$RECORD" <<EOF
{
  "version": "$VERSION",
  "name": "$NAME",
  "assistant": "$ASSISTANT",
  "timezone": "$TZONE",
  "os": "$OS",
  "installed": "$(date +%Y-%m-%dT%H:%M:%S)"
}
EOF
fi

echo "------------------------------------------------------------"
if [ "$DIFFERS" -gt 0 ]; then
  say "These Vera files differ from this version and were left alone (run with --update to refresh them; old copies are backed up):$DIFF_LIST"
fi
echo "RESULT added=$ADDED updated=$UPDATED unchanged=$UNCHANGED kept=$KEPT differs=$DIFFERS os=$OS dir=$DIR"
exit 0
