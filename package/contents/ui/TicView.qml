pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: view
    required property var controller
    Repeater {
        model: 9
        DarkButton {
            required property int index
            x: (index % 3) * view.width / 3 + 4
            y: Math.floor(index / 3) * view.height / 3 + 4
            width: view.width / 3 - 8
            height: view.height / 3 - 8
            padding: 0
            font.pixelSize: width * 0.48
            text: { view.controller.revision; const state = view.controller.state; return state && state.board ? state.board[index] : ""; }
            textColor: text === "X" ? "#8ed6ad" : "#a5c9ef"
            Accessible.name: "Cell " + (index + 1) + (text ? ", " + text : ", empty")
            onClicked: view.controller.move(index)
        }
    }
}
