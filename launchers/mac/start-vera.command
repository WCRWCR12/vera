#!/bin/bash
# {{ASSISTANT_NAME}} on Telegram (Mac).
# Double-click this file (first time: right-click > Open > Open). A window opens: leave it open while you
# want {{ASSISTANT_NAME}} on your phone. Close the window to stop. It only runs when you double-click it.
# Never add it to Login Items.
cd "$(dirname "$0")" || exit 1
# System folders first, per-user installs last, so a file planted in ~/.local/bin cannot shadow a system tool.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin:$PATH:$HOME/.local/bin:$HOME/.bun/bin"
# Anything this session writes (transcripts, notes, inbox copies) is readable by this Mac user only.
umask 077

CLAUDE_BIN="$HOME/.local/bin/claude"
[ -x "$CLAUDE_BIN" ] || CLAUDE_BIN="$(command -v claude || true)"
if [ -z "$CLAUDE_BIN" ]; then
  echo
  echo "  The Claude command-line tool is not installed yet."
  echo "  Open the Claude app, Code tab, open the Vera setup folder and say: set up Telegram"
  echo
  read -r -p "Press Return to close"; exit 1
fi

STATE="${TELEGRAM_STATE_DIR:-$HOME/.claude/channels/telegram}"
if [ ! -f "$STATE/.env" ]; then
  echo
  echo "  {{ASSISTANT_NAME}} isn't connected to Telegram yet."
  echo "  Open the Claude app, Code tab, open the Vera setup folder and say: set up Telegram"
  echo "  The bot token only ever goes into the small box Claude opens for you, never into a chat."
  echo
  read -r -p "Press Return to close"; exit 1
fi

# Telegram safety rules live in vera-settings.json. Refuse to start if the file or key rules are missing.
settings_ok() {
  [ -f vera-settings.json ] || return 1
  for r in 'disableBypassPermissionsMode' 'Edit(./.claude/**)' 'Edit(./people.md)' \
           'Read(~/.claude/channels/telegram/.env)' 'Edit(~/.claude/channels/telegram/access.json)' 'Bash(curl *)'; do
    grep -qF "$r" vera-settings.json || return 1
  done
}
if ! settings_ok; then
  echo
  echo "  vera-settings.json is missing or its safety rules were changed. Not starting."
  echo "  Ask Claude (in the Vera setup folder) to \"repair my Vera install\"."
  echo
  read -r -p "Press Return to close"; exit 1
fi
mkdir -p "$STATE/inbox"

echo "Starting {{ASSISTANT_NAME}} with Telegram. Leave this window open; close it to stop."
echo "The first time, this window may ask you to log in or to trust this folder: press Return to accept."
echo
# caffeinate keeps the Mac awake while this window is open. Only the Telegram inbox (photos, voice notes)
# is added to the assistant's reach; the token, allowlist and pairing files next to it stay outside.
caffeinate -i "$CLAUDE_BIN" --settings "$(pwd)/vera-settings.json" \
  --add-dir "$STATE/inbox" \
  --channels plugin:telegram@claude-plugins-official \
  --permission-mode default \
  "You are {{ASSISTANT_NAME}}. Read CLAUDE.md and the files it lists, then wait for messages from Telegram. Reply to every Telegram message with the Telegram reply tool."
echo
echo "  {{ASSISTANT_NAME}} has stopped. Double-click start-vera to start again."
read -r -p "Press Return to close"
