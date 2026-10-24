#!/usr/bin/env bash
# Проверяет исходники перед сборкой: синтаксис shell-скриптов, формат установщика, JSON, QML
# и корректность патча Crystal Dock. Ничего не меняет; код возврата 1, если хоть одна проверка не прошла.
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1
FAILED=0
ok()  { printf 'ok    %s\n' "$*"; }
bad() { printf 'FAIL  %s\n' "$*"; FAILED=1; }
run() { local name=$1; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }

for f in installer/install.sh scripts/*.sh; do run "bash -n $f" bash -n "$f"; done

# build.sh дописывает архив сразу после этой строки
run "installer/install.sh заканчивается строкой __PAYLOAD_BELOW__" \
  bash -c 'tail -n 1 installer/install.sh | grep -qx __PAYLOAD_BELOW__'

while IFS= read -r -d '' f; do run "json $f" python3 -m json.tool "$f"; done \
  < <(find payload -name '*.json' -print0)

QMLLINT=$(command -v qmllint6 || command -v qmllint || echo /usr/lib/qt6/bin/qmllint)
if [[ -x "$QMLLINT" ]]; then
  while IFS= read -r -d '' f; do run "qmllint $f" "$QMLLINT" "$f"; done \
    < <(find payload -name '*.qml' -print0)
else
  echo "skip  qmllint не найден — QML не проверен"
fi

for p in patches/crystal-dock/*.patch; do run "патч читается: $p" git apply --stat "$p"; done

exit "$FAILED"
