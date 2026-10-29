#!/bin/bash
# Runs every check. Pass the private terms file (kept outside the repo) for the full personal-data scan:
#   bash tests/run-all.sh [--terms <file>]
cd "$(dirname "$0")/.." || exit 1
rc=0
bash tests/test-install.sh || rc=1
bash tests/test-install.sh --os mac || rc=1
PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys' >/dev/null 2>&1; then PY="$(command -v "$c")"; break; fi
done
if [ -n "$PY" ]; then "$PY" -I tests/test-screen.py || rc=1; else echo "Python not found: skipped test-screen.py"; fi
bash tests/check-docs.sh || rc=1
bash tests/scan.sh "$@" || rc=1
[ "$rc" = 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $rc
