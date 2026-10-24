// Верхняя строка меню как в macOS: [яблоко · имя приложения · меню] … [поиск · трей] часы
// Подставляются установщиком: GS_STR (настройки Panel Colorizer), RULES_STR (замена цветных значков трея)
function buildTop(p) {
  p.height = 32; p.floating = false;
  p.widgets().forEach(function (w) { w.remove(); });
  function cfg(w, group, values) {
    w.currentConfigGroup = [group];
    for (var k in values) w.writeConfig(k, values[k]);
  }
  var apple = p.addWidget('org.kde.plasma.kickoff');
  apple.globalShortcut = 'Alt+F1';
  var title = p.addWidget('com.github.antroids.application-title-bar');
  cfg(title, 'Appearance', { widgetElements: ['windowTitle'], widgetElementsDisabledMode: 2, windowTitleSource: 0,
    windowTitleFontBold: true, windowTitleFontSize: 10, windowTitleHideEmpty: true, windowTitleUndefined: '',
    windowTitleMarginsLeft: 6, windowTitleMarginsRight: 4, widgetSpacing: 4, widgetButtonsIconsTheme: 2,
    widgetButtonsAuroraeTheme: 'MacTahoe-Dark' });
  cfg(title, 'Behavior', { widgetActiveTaskFilterByScreen: false, windowTitleDragEnabled: false,
    widgetMouseAreaLeftDragAction: '', widgetMouseAreaLeftDoubleClickAction: '', widgetMouseAreaWheelEnabled: false });
  p.addWidget('org.kde.plasma.appmenu');
  p.addWidget('org.kde.plasma.panelspacer');
  var spot = p.addWidget('org.macos.spotlight');
  var tray = p.addWidget('org.kde.plasma.systemtray');
  var gap = p.addWidget('org.kde.plasma.panelspacer');
  cfg(gap, 'General', { expanding: false, length: 2 });
  var clock = p.addWidget('org.kde.plasma.digitalclock');
  cfg(clock, 'Appearance', { dateDisplayFormat: 1, showSeconds: 0, autoFontAndSize: false, fontFamily: 'Inter',
    fontSize: 10, fontWeight: 500, dateFormat: 'custom', customDateFormat: 'ddd d MMM' });
  // «Доска приложений» на весь экран = Launchpad; сам виджет в панели скрыт, вызывается из дока и по Meta+Shift+L
  var dash = p.addWidget('org.kde.plasma.kickerdash');
  dash.globalShortcut = 'Meta+Shift+L';
  print('DASHID=' + dash.id + ';');
  if (GS_STR === '') return;
  var gs = JSON.parse(GS_STR);
  gs.configurationOverrides.associations = [
    { id: apple.id, name: 'org.kde.plasma.kickoff', presets: ['island-start'] },
    { id: tray.id, name: 'org.kde.plasma.systemtray', presets: ['island-end'] },
    { id: spot.id, name: 'org.macos.spotlight', presets: ['island-start-icon'] }];
  var c = p.addWidget('luisbocanegra.panel.colorizer');
  cfg(c, 'General', { globalSettings: JSON.stringify(gs), hideWidget: true, enableDBusService: false,
    blacklistSpacers: true, islandsEnabled: true, islandSeparatorWidget: 'org.kde.plasma.panelspacer',
    islandSeparatorPairing: false,
    blacklistedWidgets: JSON.stringify({ widgets: [{ id: clock.id, name: 'org.kde.plasma.digitalclock', blacklisted: true }] }),
    hiddenWidgets: JSON.stringify({ widgets: [{ id: dash.id, name: 'org.kde.plasma.kickerdash', hide: true }] }),
    systemTrayIconsReplacementEnabled: true, systemTrayIconUserReplacements: RULES_STR });
}
