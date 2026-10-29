#!/bin/bash
# Secrets and personal-data scan over the whole repository (everything except .git).
#   bash tests/scan.sh                          generic patterns only
#   bash tests/scan.sh --terms <file>           also every line of <file> (private names, ids, usernames),
#                                               case-sensitive, whole words. Keep that file OUTSIDE the repository.
# Exit 0 = clean. Any hit is printed as file:line (the matching text is masked).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TERMS=""; [ "${1:-}" = "--terms" ] && TERMS="${2:-}"
HITS=0

scan() { # scan LABEL ERE [grep flags]
  local label="$1" re="$2" flags="${3:-}" out
  # Generic examples in the docs ("Sam", user folders like C:\Users\Sam) are allowed.
  out="$(cd "$REPO" && grep -rnIE $flags --exclude-dir=.git --exclude=scan.sh -e "$re" . 2>/dev/null | grep -vE 'Users[\/]+[Ss]am([\/]|`|$)')"
  if [ -n "$out" ]; then
    HITS=$((HITS + $(printf '%s\n' "$out" | wc -l)))
    printf '%s\n' "$out" | cut -d: -f1,2 | sed "s/^/  HIT [$label] /"
  fi
}

echo "Scanning $REPO"
scan "telegram bot token"   '[0-9]{8,10}:[A-Za-z0-9_-]{35}'
scan "anthropic key"        'sk-ant-[A-Za-z0-9_-]{10,}'
scan "openai-style key"     'sk-[A-Za-z0-9]{32,}'
scan "google api key"       'AIza[0-9A-Za-z_-]{35}'
scan "github token"         '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}'
scan "slack token"          'xox[abprs]-[A-Za-z0-9-]{10,}'
scan "aws key"              'AKIA[0-9A-Z]{16}'
scan "private key"          '-----BEGIN [A-Z ]*PRIVATE KEY-----'
scan "env assignment"       '^(TELEGRAM_BOT_TOKEN|ANTHROPIC_API_KEY|OPENAI_API_KEY)=[^ ]+'
scan "email address"        '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
scan "phone number"         '(\+61|\+44|\+1)[ -]?[0-9][0-9 -]{7,}|\b04[0-9]{2}[ -]?[0-9]{3}[ -]?[0-9]{3}\b'
scan "telegram user id"     '\b[0-9]{9,10}\b'
scan "windows user path"    '[A-Za-z]:\\\\Users\\\\[A-Za-z]|/c/Users/[A-Za-z]|C:/Users/[A-Za-z]'
scan "mac user path"        '/Users/[a-z]+/'
if [ -n "$TERMS" ]; then
  while IFS= read -r t; do
    t="$(printf '%s' "$t" | tr -d '\r')"
    [ -z "$t" ] && continue
    case "$t" in \#*) continue ;; esac
    scan "private term" "$t" "-w"
  done < "$TERMS"
fi
# Files that must never be in the repository
bad="$(cd "$REPO" && find . -path ./.git -prune -o -type f \( -name '.env' -o -name '*.env' -o -name '.token' -o -name 'access.json' -o -name '*.pem' -o -name 'consent.json' -o -name '*.jsonl' \) -print)"
if [ -n "$bad" ]; then HITS=$((HITS + 1)); printf '%s\n' "$bad" | sed 's/^/  HIT [forbidden file] /'; fi

echo "Scan: $HITS hit(s)"
[ "$HITS" = 0 ]
