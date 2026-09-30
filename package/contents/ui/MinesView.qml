pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: view
    required property var controller
    Repeater {
        model: 81
        DarkButton {
            id: cellButton
            required property int index
            readonly property var cell: {
                view.controller.revision;
                const state = view.controller.state;
                // Publish a fresh value so nested cell mutations notify bindings.
                return state && state.cells ? Object.assign({}, state.cells[index])
                    : { mine: false, count: 0, revealed: false, flagged: false };
            }
            readonly property bool showMine: cell.mine && (cell.revealed || view.controller.ended)
            x: (index % 9) * view.width / 9 + 2
            y: Math.floor(index / 9) * view.height / 9 + 2
            width: view.width / 9 - 4
            height: view.height / 9 - 4
            padding: 0
            font.pixelSize: Math.max(12, width * 0.44)
            text: showMine ? "●" : cell.flagged ? "⚑" : cell.revealed && cell.count ? String(cell.count) : ""
            textColor: showMine ? "#f4ad88" : cell.flagged ? "#e8cf8d" : "#a5c9ef"
            baseColor: cell.revealed ? "#151b23" : "#242b35"
            Accessible.name: "Cell " + (index + 1) + (showMine ? ", mine" : cell.flagged ? ", flagged" : cell.revealed ? ", " + cell.count + " adjacent mines" : ", covered")
            onClicked: view.controller.reveal(index)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_F) { view.controller.flag(index); event.accepted = true; }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: {
                    cellButton.forceActiveFocus();
                    view.controller.flag(cellButton.index);
                }
            }
        }
    }
}
