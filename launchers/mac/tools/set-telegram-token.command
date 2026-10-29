#!/bin/bash
# Saves the Telegram bot token straight into the Telegram plugin's token file (Mac), owner-only (mode 600).
# The token is typed into a hidden macOS box. It never goes into a Claude chat, a transcript or a log,
# and this script never prints it.
#
#   bash set-telegram-token.command           opens the box
#   bash set-telegram-token.command --check   prints only "token: present" or "token: missing"
#
# The folder is the plugin's default (~/.claude/channels/telegram) unless TELEGRAM_STATE_DIR is set,
# the same rule the plugin uses.
set -u
umask 077
DIR="${TELEGRAM_STATE_DIR:-$HOME/.claude/channels/telegram}"
FILE="$DIR/.env"
PATTERN='^[0-9]{6,12}:[A-Za-z0-9_-]{30,}$'

present() {
  [ -f "$FILE" ] || return 1
  local v
  v="$(sed -n 's/^TELEGRAM_BOT_TOKEN=//p' "$FILE" | head -1 | tr -d '[:space:]')"
  printf '%s' "$v" | grep -Eq "$PATTERN"
}

if [ "${1:-}" = "--check" ]; then
  if present; then echo "token: present"; exit 0; else echo "token: missing"; exit 1; fi
fi

TOKEN="$(/usr/bin/osascript -e 'text returned of (display dialog "Paste the bot token from @BotFather, then click Save. It is saved on this Mac only and never shown in a chat." default answer "" with hidden answer with title "Vera: Telegram token" buttons {"Cancel", "Save"} default button "Save")' 2>/dev/null)" || { echo "Cancelled. Nothing saved."; exit 1; }
TOKEN="$(printf '%s' "$TOKEN" | tr -d '[:space:]')"
if ! printf '%s' "$TOKEN" | grep -Eq "$PATTERN"; then
  unset TOKEN
  /usr/bin/osascript -e 'display alert "That does not look like a bot token" message "It should be numbers, a colon, then letters. Nothing was saved."' >/dev/null 2>&1
  echo "Not a bot token. Nothing saved."; exit 1
fi
mkdir -p "$DIR"; chmod 700 "$DIR"
TMP="$(mktemp "$DIR/.env.XXXXXX")"
printf 'TELEGRAM_BOT_TOKEN=%s\n' "$TOKEN" > "$TMP"
unset TOKEN
chmod 600 "$TMP"; mv -f "$TMP" "$FILE"
[ -f "$DIR/access.json" ] && chmod 600 "$DIR/access.json"
echo "Saved. The token file is readable by this Mac user only."
