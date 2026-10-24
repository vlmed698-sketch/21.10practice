#!/usr/bin/env bash
# Собирает в vendor/ сторонние файлы, которых нет в репозитории, из темы, установленной на этом компьютере:
# иконки, курсоры и обои MacTahoe, цвета и глобальную тему, шрифты Inter и macOS, звуки macOS,
# плазмоиды Panel Colorizer и Application Title Bar, шейдеры скругления углов и собранные бинарники
# (док с патчем из patches/, Kvantum, эффект скругления, плагин Panel Colorizer).
# Структура vendor/ повторяет payload/: share/ → ~/.local/share, native/ → ~/.local.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
V="$ROOT/vendor"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
LOCAL="$HOME/.local"

SHARE=(
  color-schemes/MacTahoeDark.colors
  fonts/Inter
  "fonts/macOS/Menlo.ttc" "fonts/macOS/HelveticaNeue.ttc" "fonts/macOS/Apple Symbols.ttf"
  icons/MacTahoe icons/MacTahoe-dark icons/MacTahoe-cursors
  kwin/shaders/shapecorners.frag kwin/shaders/shapecorners_core.frag
  plasma/desktoptheme/MacTahoe-Dark
  plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Dark
  plasma/plasmoids/luisbocanegra.panel.colorizer
  plasma/plasmoids/com.github.antroids.application-title-bar
  sounds/macOS
  wallpapers/MacTahoe
)
NATIVE=(
  bin/crystal-dock bin/kvantummanager bin/kvantumpreview
  lib/qt6/plugins/styles/libkvantum.so
  lib/qt6/plugins/kwin/effects/plugins/kwin4_effect_shapecorners.so
  lib/qt6/plugins/kwin/effects/configs/kwin_shapecorners_config.so
  lib/qt6/qml/org/kde/plasma/panelcolorizer/libpanelcolorizerplugin.so
  lib/qt6/qml/org/kde/plasma/panelcolorizer/qmldir
)

copy() {  # copy <источник> <назначение>
  [[ -e "$1" ]] || { echo "Нет файла: $1" >&2; exit 1; }
  mkdir -p "$(dirname "$2")"
  cp -a "$1" "$2"
}

rm -rf -- "${V:?}"
for p in "${SHARE[@]}"; do copy "$DATA/$p" "$V/share/$p"; done
for p in "${NATIVE[@]}"; do copy "$LOCAL/$p" "$V/native/$p"; done

# В MacTahoe-dark масштабируемое «яблоко» (start-here) залито тёмным #363636, как в светлой теме:
# на панели крупнее 24 px оно почти не видно. Делаем его светлым, как варианты 16–24 px.
find "$V/share/icons/MacTahoe-dark/places/scalable" -name 'start-here*.svg' -exec sed -i 's/#363636/#dedede/g' {} +

# Локальные кэши этого компьютера не переносим: установщик пересоздаёт кэш значков сам
find "$V" \( -name icon-theme.cache -o -name .uuid \) -delete

echo "Готово: $(du -sh "$V" | cut -f1) в $V"
