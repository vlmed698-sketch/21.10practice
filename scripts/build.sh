#!/usr/bin/env bash
# Собирает один файл-установщик dist/macOS-тема-KDE.sh:
# installer/install.sh + архив tar.xz из payload/ (файлы репозитория) и vendor/ (сторонние файлы).
# Перед первой сборкой выполните scripts/collect-vendor.sh.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/dist/macOS-тема-KDE.sh"
[[ -d "$ROOT/vendor" ]] || { echo "Нет vendor/ — сначала запустите scripts/collect-vendor.sh" >&2; exit 1; }
tail -n 1 "$ROOT/installer/install.sh" | grep -qx '__PAYLOAD_BELOW__' \
  || { echo "installer/install.sh должен заканчиваться строкой __PAYLOAD_BELOW__" >&2; exit 1; }
bash -n "$ROOT/installer/install.sh"

STAGE=$(mktemp -d)
trap 'rm -rf -- "${STAGE:?}"' EXIT
cp -a "$ROOT/payload/." "$STAGE/"
cp -a "$ROOT/vendor/." "$STAGE/"

mkdir -p "$ROOT/dist"
{ cat "$ROOT/installer/install.sh"; tar -C "$STAGE" --owner=0 --group=0 -cf - . | xz -T0 -6; } > "$OUT.new"
chmod +x "$OUT.new"
mv -f "$OUT.new" "$OUT"
echo "Готово: $OUT ($(du -h "$OUT" | cut -f1))"
