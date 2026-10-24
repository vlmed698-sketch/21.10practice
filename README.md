# macos-kde-theme

Оформление KDE Plasma 6.8 (Wayland) в стиле macOS: строка меню со стеклянными «пилюлями»,
«светофор» в заголовках окон, матовый док, Launchpad, поиск в духе Spotlight.
Всё ставится без sudo — только в `~/.local` и `~/.config` — одним файлом-установщиком.

Основа — темы [MacTahoe](https://github.com/vinceliuice/MacTahoe-kde) (vinceliuice);
в этом репозитории хранятся собственные доработки и скрипты, которые собирают из них установщик.

## Что входит в тему

- **Строка меню** — слева одна «пилюля»: яблоко, жирное имя активного приложения и его меню;
  справа «пилюля» с поиском и треем (значки монохромные), часы без подложки.
- **Окна** — рамки MacTahoe-Dark с «светофором» слева, скругление углов, прозрачность Kvantum, анимации как в macOS.
- **Док** — Crystal Dock с патчем: матовое стекло, увеличение при наведении, Launchpad, «Загрузки» и Корзина.
- **Шрифты и звуки** — Inter, Menlo и Helvetica Neue, звуковая тема macOS, профиль Konsole.

## Структура

| Путь | Содержимое |
|---|---|
| `installer/install.sh` | первая часть установщика: применение темы, резервная копия и откат |
| `payload/` | собственные файлы темы; `share/` → `~/.local/share`, `config/` → `~/.config` |
| `payload/extra/` | скрипт сборки строки меню и правила значков трея (используются установщиком) |
| `patches/crystal-dock/` | патч к Crystal Dock v2.16 |
| `scripts/collect-vendor.sh` | собирает сторонние файлы в `vendor/` с установленной системы |
| `scripts/build.sh` | собирает `dist/macOS-тема-KDE.sh` |
| `scripts/check.sh` | проверяет исходники перед сборкой |
| `docs/hotkeys.md` | горячие клавиши |

Сторонние файлы (иконки, курсоры и обои MacTahoe, шрифты, звуки, плазмоиды Panel Colorizer
и Application Title Bar, собранные бинарники) в репозиторий не входят — см. `.gitignore`.

## Сборка установщика

Нужна система, где тема уже установлена (из неё берутся сторонние файлы). Сначала проверьте исходники:

```bash
scripts/check.sh            # синтаксис скриптов, JSON, QML, патч
scripts/collect-vendor.sh   # → vendor/
scripts/build.sh            # → dist/macOS-тема-KDE.sh
```

Док собирается отдельно из исходников Crystal Dock с патчем:

```bash
git clone --depth 1 --branch v2.16 https://github.com/dangvd/crystal-dock.git build/crystal-dock
git -C build/crystal-dock apply ../../patches/crystal-dock/0001-macos-style.patch
```

Нужны CMake, extra-cmake-modules, Qt 6, LayerShellQt и KF6 WindowSystem; готовый `crystal-dock`
копируется в `~/.local/bin/` до запуска `collect-vendor.sh`.

## Установка

Двойной клик по `macOS-тема-KDE.sh` в Dolphin → «Выполнить», или:

```bash
bash macOS-тема-KDE.sh
```

Проверка без применения к текущему сеансу: `MACOS_THEME_NO_APPLY=1 bash macOS-тема-KDE.sh`.
Док, Kvantum, скругление углов и размытие под «пилюлями» ставятся только на Qt 6.12.0 и Plasma 6.8.1
(под эти версии собраны бинарники); на других версиях они пропускаются.

Откат — скрипт `откат.sh` в папке резервной копии `~/.local/share/macos-theme-backup/<дата>/`,
путь к нему установщик выводит в конце.

## Лицензии

Темы MacTahoe, Crystal Dock, Panel Colorizer и Application Title Bar распространяются по GPL-3.0,
шрифт Inter — по SIL Open Font License. Шрифты и звуки Apple — собственность Apple,
поэтому они не хранятся в репозитории и берутся только с вашей системы.
