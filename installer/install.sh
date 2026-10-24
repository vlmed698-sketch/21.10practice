#!/usr/bin/env bash
# Установщик оформления KDE Plasma 6 в стиле macOS (MacTahoe-Dark «жидкое стекло» + Inter) — итоговый вариант
# (24.10: строка меню как в macOS — «пилюли» [яблоко · имя приложения · меню] и [поиск · трей], часы без подложки,
#  Launchpad, матовый док с «Загрузками», шрифты Menlo/Helvetica Neue и звуки macOS, профиль Konsole).
# Работает без sudo: всё ставится в ~/.local и ~/.config.
# Запуск: двойной клик в Dolphin → «Выполнить», или в терминале:  bash "этот файл"
# Тестовый режим без применения к живому сеансу:  MACOS_THEME_NO_APPLY=1 bash "этот файл"
set -euo pipefail

LAF=com.github.vinceliuice.MacTahoe-Dark
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL="$HOME/.local"
STAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP="$DATA/macos-theme-backup/$STAMP"
NO_APPLY="${MACOS_THEME_NO_APPLY:-}"
# Самосборные части (док, Kvantum, скругление углов, размытие под элементами панели) собраны под эти версии:
NATIVE_QT=6.12.0
NATIVE_PLASMA=6.8.1

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
notify() {
  command -v notify-send >/dev/null && notify-send -i preferences-desktop-theme "macOS-тема" "$1" || true
  command -v kdialog >/dev/null && [[ -z "$NO_APPLY" ]] && kdialog --title "macOS-тема" --msgbox "$1" 2>/dev/null || true
}
fail() { echo "Ошибка: $*" >&2; notify "Ошибка: $*"; exit 1; }
kw() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }

for t in kwriteconfig6 kreadconfig6 tar xz; do command -v "$t" >/dev/null || fail "не найдена программа $t (нужна KDE Plasma 6)"; done
if [[ -z "$NO_APPLY" ]]; then
  for t in plasma-apply-lookandfeel plasma-apply-colorscheme plasma-apply-desktoptheme plasma-apply-cursortheme qdbus6; do
    command -v "$t" >/dev/null || fail "не найдена программа $t (нужна KDE Plasma 6)"
  done
fi

# Версии Qt и Plasma на этом компьютере
QT_VER=$(ls /usr/lib/libQt6Core.so.6.* /usr/lib64/libQt6Core.so.6.* /usr/lib/*-linux-gnu/libQt6Core.so.6.* 2>/dev/null \
         | grep -oE '6\.[0-9]+\.[0-9]+$' | head -1 || true)
PLASMA_VER=$(kwin_wayland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
NATIVE=""
if [[ "$(uname -m)" == x86_64 && "$QT_VER" == "$NATIVE_QT" && "$PLASMA_VER" == "$NATIVE_PLASMA" ]]; then NATIVE=1; fi
AURORAE_V2=""
for d in /usr/lib/qt6/plugins /usr/lib64/qt6/plugins /usr/lib/*-linux-gnu/qt6/plugins; do
  [[ -f "$d/org.kde.kdecoration3/org.kde.kwin.aurorae.v2.so" ]] && AURORAE_V2=1
done

# 1. Бэкап текущих настроек (+ список файлов, которых раньше не было — их удалит откат)
say "Сохраняю текущие настройки в $BACKUP"
mkdir -p "$BACKUP"
for f in kdeglobals kwinrc kcminputrc plasmarc ksplashrc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc krunnerrc \
         dolphinrc kglobalshortcutsrc konsolerc; do
  if [[ -f "$CONF/$f" ]]; then cp -a "$CONF/$f" "$BACKUP/"; fi
done
for d in kdedefaults gtk-3.0 gtk-4.0; do
  if [[ -d "$CONF/$d" ]]; then cp -a "$CONF/$d" "$BACKUP/"; fi
done
if [[ -f "$DATA/user-places.xbel" ]]; then cp -a "$DATA/user-places.xbel" "$BACKUP/"; fi
if [[ -f "$CONF/Kvantum/kvantum.kvconfig" ]]; then cp -a "$CONF/Kvantum/kvantum.kvconfig" "$BACKUP/"; fi
OLD_LAF=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null || true)
: > "$BACKUP/created.txt"
track() { if [[ ! -e "$1" ]]; then echo "$1" >> "$BACKUP/created.txt"; fi; }

# 2. Распаковка: тема, иконки, курсоры, обои, шрифт, виджет панели, настройки Kvantum/дока
say "Распаковываю файлы темы"
TMP=$(mktemp -d)
trap 'rm -rf -- "${TMP:?}"' EXIT
LINE=$(awk '/^__PAYLOAD_BELOW__$/ { print NR + 1; exit }' "$0")
tail -n +"$LINE" "$0" | tar -xJ -C "$TMP"
for f in kxmlgui5/dolphin/dolphinui.rc kwin/shaders/shapecorners.frag kwin/shaders/shapecorners_core.frag \
         plasma/plasmoids/com.github.antroids.application-title-bar plasma/plasmoids/org.macos.spotlight \
         fonts/macOS sounds/macOS konsole/macOS.profile; do track "$DATA/$f"; done
mkdir -p "$DATA" "$CONF"
cp -a "$TMP/share/." "$DATA/"
track "$CONF/panel-colorizer"; track "$CONF/Kvantum/MacTahoeGlass"; track "$CONF/fontconfig/conf.d/50-macos-fonts.conf"
cp -a "$TMP/config/." "$CONF/"
command -v fc-cache >/dev/null && fc-cache -f "$DATA/fonts" >/dev/null 2>&1 || true
if command -v gtk-update-icon-cache >/dev/null; then
  for i in MacTahoe MacTahoe-dark; do gtk-update-icon-cache -q -f "$DATA/icons/$i" 2>/dev/null || true; done
fi

# 2b. Самосборные части — только при точном совпадении версий (иначе могут уронить KWin/Plasma)
if [[ -n "$NATIVE" ]]; then
  say "Qt $QT_VER и Plasma $PLASMA_VER совпадают — ставлю док, Kvantum, скругление углов и размытие панели"
  (cd "$TMP/native" && find . -type f) | while read -r f; do
    dst="$LOCAL/${f#./}"; track "$dst"; mkdir -p "$(dirname "$dst")"
    # через временный файл + переименование: безопасно, даже если старая версия уже загружена в память
    install -m755 "$TMP/native/$f" "$dst.new" && mv -f "$dst.new" "$dst"
  done
  mkdir -p "$CONF/environment.d" "$CONF/plasma-workspace/env" "$CONF/autostart" "$DATA/applications"
  track "$CONF/environment.d/90-macos-theme.conf"
  printf 'QT_PLUGIN_PATH=%s/lib/qt6/plugins\nQML_IMPORT_PATH=%s/lib/qt6/qml\n' "$LOCAL" "$LOCAL" > "$CONF/environment.d/90-macos-theme.conf"
  track "$CONF/plasma-workspace/env/macos-theme.sh"
  cat > "$CONF/plasma-workspace/env/macos-theme.sh" <<'ENV'
#!/bin/sh
# Kvantum, плагин панели и эффект углов, собранные в домашней папке (без sudo)
export QT_PLUGIN_PATH="$HOME/.local/lib/qt6/plugins${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
export QML_IMPORT_PATH="$HOME/.local/lib/qt6/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
ENV
  chmod +x "$CONF/plasma-workspace/env/macos-theme.sh"
  track "$DATA/applications/crystal-dock.desktop"
  cat > "$DATA/applications/crystal-dock.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Crystal Dock
GenericName=Desktop Panel
Icon=user-desktop
Exec=$LOCAL/bin/crystal-dock
Terminal=false
Categories=Utility;
X-KDE-Wayland-Interfaces=org_kde_plasma_window_management
DESK
  track "$CONF/autostart/crystal-dock.desktop"
  cat > "$CONF/autostart/crystal-dock.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Crystal Dock
Exec=env QT_STYLE_OVERRIDE=Breeze $LOCAL/bin/crystal-dock
Icon=user-desktop
X-KDE-autostart-phase=2
DESK
  # Док: закреплённые приложения — только те, что есть на этом компьютере (id в нижнем регистре)
  appdirs=(/usr/share/applications /var/lib/flatpak/exports/share/applications "$DATA/flatpak/exports/share/applications")
  have() { for d in "${appdirs[@]}"; do [[ -f "$d/$1.desktop" ]] && return 0; done; return 1; }
  L="org.kde.dolphin;macos-launchpad"   # Launchpad вторым, как в macOS (ярлык создаётся в шаге 8)
  br=$(xdg-settings get default-web-browser 2>/dev/null || true); br=${br%.desktop}
  for app in "$br" com.spotify.Client spotify steam discord com.discordapp.Discord dev.vencord.Vesktop \
             org.telegram.desktop io.github.snowyfluffy.freshgram org.kde.konsole systemsettings; do
    [[ -n "$app" ]] && have "$app" && L+=";${app,,}"
  done
  mkdir -p "$CONF/crystal-dock/KDE"; track "$CONF/crystal-dock/KDE/panel_1.conf"
  cat > "$CONF/crystal-dock/KDE/panel_1.conf" <<DOCK
[General]
position=1
screen=0
visibility=3
showApplicationMenu=false
showPager=false
showTaskManager=true
showTrash=true
showWifiManager=false
showVolumeControl=false
showBatteryIndicator=false
showKeyboardLayout=false
showVersionChecker=false
showClock=false
launchers="$L"

[TaskManager]
currentScreenTasksOnly=true
groupTasksByApplication=true
DOCK
  # Справа в доке (перед Корзиной, после разделителя) — стопка «Загрузки»
  DL=$(xdg-user-dir DOWNLOAD 2>/dev/null || true); [[ -z "$DL" || "$DL" == "$HOME" ]] && DL="$HOME/Downloads"
  track "$DATA/applications/macos-downloads-stack.desktop"
  cat > "$DATA/applications/macos-downloads-stack.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Загрузки
Comment=Папка загрузок (как стопка Downloads в доке macOS)
Icon=folder-download
Exec=xdg-open "$DL"
Terminal=false
Categories=Utility;
NoDisplay=true
DESK
else
  say "Qt ${QT_VER:-?} / Plasma ${PLASMA_VER:-?} (сборка под Qt $NATIVE_QT / Plasma $NATIVE_PLASMA) — док Crystal Dock, Kvantum, скругление углов и размытие под элементами панели пропускаю; остальное ставлю"
fi

# 3. Глобальная тема (цвета, Plasma, иконки, курсоры, окна) + новая раскладка панелей
if [[ -z "$NO_APPLY" ]]; then
  say "Применяю тему MacTahoe-Dark (верхняя панель + док)"
  plasma-apply-lookandfeel -a "$LAF" --resetLayout || true
  sleep 3
  plasma-apply-colorscheme MacTahoeDark >/dev/null || true
  plasma-apply-desktoptheme MacTahoe-Glass >/dev/null || true
  # Курсоры из ~/.local/share/icons не видны plasma-apply-cursortheme — даём ссылку в ~/.icons
  mkdir -p "$HOME/.icons"; track "$HOME/.icons/MacTahoe-cursors"; ln -sfn "$DATA/icons/MacTahoe-cursors" "$HOME/.icons/MacTahoe-cursors"
  plasma-apply-cursortheme MacTahoe-cursors >/dev/null || kw kcminputrc Mouse cursorTheme MacTahoe-cursors
  if [[ -x /usr/lib/plasma-changeicons ]]; then /usr/lib/plasma-changeicons MacTahoe-dark >/dev/null 2>&1 || true
  else kw kdeglobals Icons Theme MacTahoe-dark; fi
else
  kw kdeglobals General ColorScheme MacTahoeDark
  kw kdeglobals Icons Theme MacTahoe-dark
  kw plasmarc Theme name MacTahoe-Glass
  kw kcminputrc Mouse cursorTheme MacTahoe-cursors
fi
if [[ -n "$NATIVE" ]]; then
  kw kdeglobals KDE widgetStyle kvantum
  track "$CONF/Kvantum/kvantum.kvconfig"; printf '[General]\ntheme=MacTahoeGlass\n' > "$CONF/Kvantum/kvantum.kvconfig"
else
  kw kdeglobals KDE widgetStyle Breeze
fi

# 4. Рамки окон: «светофоры» слева, без видимой рамки по краям; потянуть за край — невидимая зона (Aurorae v2)
say "Настраиваю рамки окон"
if [[ -n "$AURORAE_V2" ]]; then kw kwinrc org.kde.kdecoration2 library org.kde.kwin.aurorae.v2; kw kwinrc org.kde.kdecoration2 BorderSize None
else kw kwinrc org.kde.kdecoration2 library org.kde.kwin.aurorae; kw kwinrc org.kde.kdecoration2 BorderSize Tiny; fi
kw kwinrc org.kde.kdecoration2 BorderSizeAuto false
kw kwinrc org.kde.kdecoration2 theme __aurorae__svg__MacTahoe-Dark
kw kwinrc org.kde.kdecoration2 ButtonsOnLeft XIA
kw kwinrc org.kde.kdecoration2 ButtonsOnRight ""
if [[ -n "$NATIVE" ]]; then   # скругление всех 4 углов (радиус как у заголовка темы), без чёрной обводки
  kw kwinrc Plugins kwin4_effect_shapecornersEnabled true
  for kv in Size=24 InactiveCornerRadius=24 UseSquircleShape=false OutlineThickness=0 InactiveOutlineThickness=0 \
            SecondOutlineThickness=0 InactiveSecondOutlineThickness=0; do kw kwinrc Round-Corners "${kv%%=*}" "${kv#*=}"; done
fi

# 4b. Стекло, Alt+Tab «Cover Flow», поиск по центру как Spotlight (Win+Пробел)
say "Настраиваю размытие, Alt+Tab и поиск"
kw kwinrc Effect-blur BlurStrength 8
kw kwinrc Effect-blur NoiseStrength 3
kw kwinrc TabBox LayoutName coverswitch
kw kwinrc TabBox DelayTime 0
kw krunnerrc General FreeFloating true
kwriteconfig6 --file kglobalshortcutsrc --group services --group org.kde.krunner.desktop --key _launch "Meta+Space	Alt+Space	Alt+F2	Search"

# 5. Шрифт Inter, чёткое сглаживание
say "Ставлю шрифт Inter"
F="Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw kdeglobals General font "$F"
kw kdeglobals General menuFont "$F"
kw kdeglobals General toolBarFont "Inter,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw kdeglobals General smallestReadableFont "Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw kdeglobals WM activeFont "Inter,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1"
kw kdeglobals General XftHintStyle hintslight
kw kdeglobals General XftSubPixel rgb
kw kdeglobals General XftAntialias true

# 5b. Шрифты и звуки macOS: Menlo в терминале, Helvetica Neue вместо SF Pro, звуковая тема macOS
say "Ставлю шрифты Menlo / Helvetica Neue и звуки macOS"
command -v fc-cache >/dev/null && fc-cache -f "$DATA/fonts/macOS" >/dev/null 2>&1 || true
kw kdeglobals Sounds Theme macOS
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile macOS.profile
# Значок Cachy-Update/Arch-Update в трее — белый, как остальные (его штатная настройка)
if command -v arch-update >/dev/null && [[ ! -f "$CONF/arch-update/arch-update.conf" ]]; then
  mkdir -p "$CONF/arch-update"; track "$CONF/arch-update/arch-update.conf"
  printf 'TrayIconStyle=light\n' > "$CONF/arch-update/arch-update.conf"
fi

# 6. Анимации как в macOS, быстрый отклик
say "Включаю анимации в стиле macOS"
for kv in squashEnabled=false magiclampEnabled=true sheetEnabled=true scaleEnabled=true glideEnabled=false \
          fadeEnabled=false blurEnabled=true slideEnabled=true wobblywindowsEnabled=false; do
  kw kwinrc Plugins "${kv%%=*}" "${kv#*=}"
done
kw kwinrc Effect-magiclamp AnimationDuration 220
kw kdeglobals KDE AnimationDurationFactor 0.5
kw plasmarc PlasmaToolTips Delay 250
kw kwinrc Xwayland XwaylandClientsScale true

# 6b. Dolphin как Finder: панель инструментов Finder, без строки меню (есть глобальное меню), лишние разделы скрыты
say "Настраиваю Dolphin"
kw dolphinrc MainWindow MenuBar Disabled
kwriteconfig6 --file dolphinrc --group MainWindow --group "Toolbar mainToolBar" --key ToolButtonStyle IconOnly
kw dolphinrc General ShowZoomSlider false
kw dolphinrc General ShowSpaceInfo false
kw dolphinrc PlacesPanel IconSize 16
if [[ -f "$DATA/user-places.xbel" ]]; then
  sed -i 's|<GroupState-Remote-IsHidden>false|<GroupState-Remote-IsHidden>true|; s|<GroupState-RecentlySaved-IsHidden>false|<GroupState-RecentlySaved-IsHidden>true|' "$DATA/user-places.xbel"
fi

# 7. GTK-приложения: шрифт, иконки, курсоры, кнопки слева
say "Настраиваю GTK-приложения"
for g in gtk-3.0 gtk-4.0; do
  ini="$CONF/$g/settings.ini"; mkdir -p "$CONF/$g"; [[ -f "$ini" ]] || echo "[Settings]" > "$ini"
  setini() { if grep -q "^$1=" "$ini"; then sed -i "s|^$1=.*|$1=$2|" "$ini"; else echo "$1=$2" >> "$ini"; fi; }
  setini gtk-font-name "Inter,  10"
  setini gtk-icon-theme-name MacTahoe-dark
  setini gtk-cursor-theme-name MacTahoe-cursors
  setini gtk-decoration-layout "close,minimize,maximize:"
  setini gtk-application-prefer-dark-theme true
done
if command -v gsettings >/dev/null && [[ -z "$NO_APPLY" ]]; then
  gsettings set org.gnome.desktop.interface font-name 'Inter 10' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme 'MacTahoe-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme 'MacTahoe-cursors' 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
fi

# 8. Обои, верхняя панель (прозрачная, элементы на стеклянных «пилюлях»), док
if [[ -z "$NO_APPLY" ]]; then
  say "Настраиваю обои, верхнюю панель и док"
  if [[ -n "$NATIVE" ]]; then
    systemctl --user set-environment QT_PLUGIN_PATH="$LOCAL/lib/qt6/plugins" QML_IMPORT_PATH="$LOCAL/lib/qt6/qml" 2>/dev/null || true
    dbus-update-activation-environment --systemd QT_PLUGIN_PATH="$LOCAL/lib/qt6/plugins" QML_IMPORT_PATH="$LOCAL/lib/qt6/qml" 2>/dev/null || true
  fi
  # перезапуск — чтобы оболочка увидела новые виджеты (имя приложения, поиск) и плагин панели
  systemctl --user restart plasma-plasmashell.service >/dev/null 2>&1 || true
  sleep 5
  launchers='"preferred://filemanager","preferred://browser"'
  for app in com.spotify.Client spotify steam discord com.discordapp.Discord org.telegram.desktop org.kde.konsole systemsettings; do
    for dir in /usr/share/applications /var/lib/flatpak/exports/share/applications "$DATA/flatpak/exports/share/applications"; do
      if [[ -f "$dir/$app.desktop" ]]; then launchers+=",\"applications:$app.desktop\""; break; fi
    done
  done
  GS=$(python3 -c 'import json,sys;print(json.dumps(json.dumps(json.load(open(sys.argv[1]))["globalSettings"])))' \
       "$CONF/panel-colorizer/presets/macOS Glass/settings.json" 2>/dev/null || echo '""')
  RULES=$(python3 -c 'import json,sys;print(json.dumps(json.dumps(json.load(open(sys.argv[1])))))' \
       "$TMP/extra/tray-icon-rules.json" 2>/dev/null || echo '"[]"')
  REMOVE_BOTTOM=false; [[ -n "$NATIVE" ]] && REMOVE_BOTTOM=true
  img="file://$DATA/wallpapers/MacTahoe/"  # пакет с images и images_dark — меняется вместе со светлой/тёмной темой
  OUT=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var GS_STR = $GS; var RULES_STR = $RULES;
$(cat "$TMP/extra/top-panel.js")
desktops().forEach(function(d){ d.wallpaperPlugin='org.kde.image'; d.currentConfigGroup=['Wallpaper','org.kde.image','General']; d.writeConfig('Image','$img'); });
panels().forEach(function(p){
  if (p.location === 'bottom') {
    if ($REMOVE_BOTTOM) { p.remove(); return; }
    p.alignment='center'; p.lengthMode='fit'; p.hiding='dodgewindows'; p.floating=true; p.height=56;
    p.widgets('org.kde.plasma.icontasks').forEach(function(t){ t.currentConfigGroup=['General']; t.writeConfig('launchers',[$launchers]); t.writeConfig('iconSpacing',2); });
  }
  if (p.location === 'top') { buildTop(p); p.height = 32; }
});
var ids = [];
panels().concat(desktops()).forEach(function(c){ ids = ids.concat(c.widgetIds); });
print('IDS=' + ids.join(',') + ';');" 2>/dev/null || true)
  # Сочетания удалённых виджетов остаются в kglobalaccel и перехватывают Alt+F1 / Meta+Shift+L — снимаем их
  LIVE=$(grep -oE 'IDS=[0-9,]*' <<<"$OUT" | cut -d= -f2 || true)
  if [[ -n "$LIVE" ]]; then
    for n in $(qdbus6 org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.shortcutNames 2>/dev/null \
               | grep -oE '^activate widget [0-9]+$' | grep -oE '[0-9]+$' || true); do
      [[ ",$LIVE," == *",$n,"* ]] || qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.unregister plasmashell "activate widget $n" >/dev/null 2>&1 || true
    done
  fi
  # Launchpad (значок в доке) открывает «Доску приложений» из верхней панели
  DASHID=$(grep -oE 'DASHID=[0-9]+' <<<"$OUT" | cut -d= -f2 || true)
  if [[ -n "$DASHID" ]]; then
    mkdir -p "$DATA/applications"; track "$DATA/applications/macos-launchpad.desktop"
    cat > "$DATA/applications/macos-launchpad.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Launchpad
Comment=Сетка всех приложений (Доска приложений Plasma), как Launchpad в macOS
Icon=view-app-grid
Exec=qdbus6 org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut "activate widget $DASHID"
Terminal=false
Categories=Utility;
NoDisplay=true
DESK
  fi

  # Панели всегда прозрачные (не переключаются на сплошной фон при развёрнутом окне)
  sleep 1
  grep -oE '^\[PlasmaViews\]\[Panel [0-9]+\]$' "$CONF/plasmashellrc" 2>/dev/null | grep -oE '[0-9]+' | while read -r id; do
    kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity 2
  done
  systemctl --user restart plasma-plasmashell.service >/dev/null 2>&1 || true

  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect blur >/dev/null 2>&1 || true
  for e in squash glide fade; do qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect $e >/dev/null 2>&1 || true; done
  for e in magiclamp sheet scale slide blur; do qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect $e >/dev/null 2>&1 || true; done
  if [[ -n "$NATIVE" ]]; then
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect kwin4_effect_shapecorners >/dev/null 2>&1 || true
    pgrep -x crystal-dock >/dev/null || systemd-run --user --collect --unit=crystal-dock --setenv=QT_STYLE_OVERRIDE=Breeze \
      "$LOCAL/bin/crystal-dock" >/dev/null 2>&1 || (QT_STYLE_OVERRIDE=Breeze setsid "$LOCAL/bin/crystal-dock" >/dev/null 2>&1 &)
  fi
fi

# 9. Скрипт отката
cat > "$BACKUP/откат.sh" <<EOF
#!/usr/bin/env bash
# Возвращает оформление, бывшее до установки macOS-темы ($STAMP).
B="$BACKUP"
pkill -x crystal-dock 2>/dev/null || true
plasma-apply-lookandfeel -a "${OLD_LAF:-org.kde.breezedark.desktop}" --resetLayout || true
sleep 3
for f in kdeglobals kwinrc kcminputrc plasmarc ksplashrc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc krunnerrc dolphinrc kglobalshortcutsrc konsolerc; do
  [[ -f "\$B/\$f" ]] && cp -a "\$B/\$f" "$CONF/"
done
for d in kdedefaults gtk-3.0 gtk-4.0; do [[ -d "\$B/\$d" ]] && rm -rf -- "$CONF/\${d:?}" && cp -a "\$B/\$d" "$CONF/"; done
[[ -f "\$B/user-places.xbel" ]] && cp -a "\$B/user-places.xbel" "$DATA/"
[[ -f "\$B/kvantum.kvconfig" ]] && cp -a "\$B/kvantum.kvconfig" "$CONF/Kvantum/"
# файлы и папки, которых до установки не было
while read -r p; do [[ -n "\$p" && "\$p" == "$HOME/"* ]] && rm -rf -- "\${p:?}"; done < "\$B/created.txt"
systemctl --user unset-environment QT_PLUGIN_PATH QML_IMPORT_PATH 2>/dev/null || true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
echo "Готово. Выйдите из сеанса и войдите снова, чтобы всё вернулось полностью."
echo "Файлы темы можно удалить вручную: $DATA/{aurorae/themes/MacTahoe-Dark,color-schemes/MacTahoeDark.colors,plasma/desktoptheme/MacTahoe-Dark,plasma/desktoptheme/MacTahoe-Glass,plasma/look-and-feel/$LAF,plasma/plasmoids/luisbocanegra.panel.colorizer,plasma/plasmoids/com.github.antroids.application-title-bar,plasma/plasmoids/org.macos.spotlight,wallpapers/MacTahoe,icons/MacTahoe,icons/MacTahoe-dark,icons/MacTahoe-cursors,fonts/Inter}"
EOF
chmod +x "$BACKUP/откат.sh"

say "Готово!"
if [[ -n "$NATIVE" ]]; then EXTRA="Док, Kvantum и скругление углов установлены."
else EXTRA="Док Crystal Dock, Kvantum и скругление углов пропущены: собраны под Qt $NATIVE_QT / Plasma $NATIVE_PLASMA, здесь Qt ${QT_VER:-?} / Plasma ${PLASMA_VER:-?}."; fi
MSG="Оформление macOS применено.
$EXTRA
Выйдите из сеанса и войдите снова — тогда всё подхватится полностью.
Откат: $BACKUP/откат.sh"
echo "$MSG"
notify "$MSG"
exit 0
__PAYLOAD_BELOW__
