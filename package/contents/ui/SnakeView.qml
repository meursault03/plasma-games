pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: view
    required property var controller
    readonly property var cells: {
        controller.revision;
        const result = new Array(400).fill(0);
        const state = controller.state;
        if (state && state.body) {
            for (let i = 0; i < state.body.length; ++i) result[state.body[i]] = i === 0 ? 2 : 1;
            if (state.food >= 0) result[state.food] = 3;
        }
        return result;
    }
    Rectangle { anchors.fill: parent; color: "#11161d"; radius: 8 }
    Repeater {
        model: 400
        Rectangle {
            required property int index
            readonly property int type: view.cells[index]
            x: (index % 20) * view.width / 20 + 1
            y: Math.floor(index / 20) * view.height / 20 + 1
            width: view.width / 20 - 2
            height: view.height / 20 - 2
            radius: type === 3 ? width / 2 : 3
            visible: type !== 0
            color: type === 3 ? "#f4ad88" : type === 2 ? "#c0f1d0" : "#78c99b"
        }
    }
}
