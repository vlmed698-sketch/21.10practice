// Значок поиска в строке меню (как Spotlight в macOS): по нажатию показывает KRunner.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.icon: "system-search-symbolic"
    toolTipMainText: i18n("Поиск")
    toolTipSubText: i18n("Открыть поиск KRunner (Alt+Пробел)")

    function showSearch() {
        DBus.SessionBus.asyncCall({
            "service": "org.kde.krunner",
            "path": "/App",
            "iface": "org.kde.krunner.App",
            "member": "toggleDisplay",
            "arguments": []
        });
    }

    fullRepresentation: Kirigami.Icon {
        id: icon
        source: "system-search-symbolic"
        active: area.containsMouse
        isMask: true
        color: Kirigami.Theme.textColor
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: root.showSearch()
        }
    }
}
