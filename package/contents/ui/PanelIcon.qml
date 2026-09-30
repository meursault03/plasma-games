import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: panelIcon
    implicitWidth: 24
    implicitHeight: 24
    Layout.minimumWidth: 24
    Layout.minimumHeight: 24
    Layout.preferredWidth: 24
    Layout.preferredHeight: 24
    signal activated()

    Kirigami.Icon {
        id: glyph
        objectName: "panelGlyph"
        anchors.centerIn: parent
        width: Math.min(Kirigami.Units.iconSizes.smallMedium, panelIcon.width, panelIcon.height)
        height: width
        source: Qt.resolvedUrl("../images/games.svg")
        isMask: true
        color: "#ffffff"
    }
    Rectangle {
        anchors.fill: glyph
        anchors.margins: -3
        radius: 5
        color: "transparent"
        border.width: panelIcon.activeFocus ? 1 : 0
        border.color: "#ffffff"
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: panelIcon.activated()
    }
    Accessible.name: "Plasma Games"
    Accessible.role: Accessible.Button
    Accessible.onPressAction: panelIcon.activated()
    activeFocusOnTab: true
    Keys.onSpacePressed: event => { if (!event.isAutoRepeat) panelIcon.activated(); }
    Keys.onReturnPressed: event => { if (!event.isAutoRepeat) panelIcon.activated(); }
}
