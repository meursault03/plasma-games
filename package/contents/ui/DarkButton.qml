import QtQuick
import QtQuick.Controls

Button {
    id: button
    property color textColor: "#e6e9ee"
    property color baseColor: "#242b35"
    hoverEnabled: true
    padding: 12
    implicitHeight: 44
    contentItem: Text {
        text: button.text
        color: button.enabled ? button.textColor : "#8290a3"
        font: button.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 8
        color: button.down ? Qt.darker(button.baseColor, 1.15)
             : button.hovered ? Qt.lighter(button.baseColor, 1.16) : button.baseColor
        border.width: button.activeFocus ? 2 : 1
        border.color: button.activeFocus ? "#8ed6ad" : "#364151"
    }
}
