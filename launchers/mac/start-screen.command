#!/bin/bash
# Vera Screen (Mac). Double-click (first time: right-click > Open > Open). It starts on this Mac only
# (127.0.0.1:5191) and opens in your browser. Close this window to stop it. It never starts by itself.
cd "$(dirname "$0")/screen" || exit 1
umask 077
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin:$PATH"
PY="$(command -v python3 || true)"
if [ -z "$PY" ] || ! "$PY" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' >/dev/null 2>&1; then
  echo
  echo "  Vera Screen needs Python 3.9 or newer."
  echo "  Open the Claude app, Code tab, open the Vera setup folder and say: set up Vera Screen"
  echo
  read -r -p "Press Return to close"; exit 1
fi
exec "$PY" -E -s server.py --open
