pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: view
    required property var controller
    property bool ready: false
    readonly property bool animationAllowed: ready && visible && controller.interactive
    function activateKey(index: int): void {
        if (controller.ended) controller.restart();
        else controller.pressLight(index);
    }
    Component.onCompleted: ready = true
    Repeater {
        model: 25
        DarkButton {
            id: lightButton
            required property int index
            readonly property bool lit: {
                view.controller.revision;
                const state = view.controller.state;
                return state && state.cells ? state.cells[index] : false;
            }
            x: (index % 5) * view.width / 5 + 3
            y: Math.floor(index / 5) * view.height / 5 + 3
            width: view.width / 5 - 6
            height: view.height / 5 - 6
            padding: 0
            autoRepeat: false
            baseColor: lit ? "#527e62" : "#202731"
            hoverEnabled: !view.controller.ended
            Accessible.name: "Light " + (index + 1) + (lit ? ", on" : ", off")
            onClicked: view.controller.pressLight(index)
            Keys.onReturnPressed: event => {
                if (!event.isAutoRepeat) view.activateKey(index);
                event.accepted = true;
            }
            Keys.onEnterPressed: event => {
                if (!event.isAutoRepeat) view.activateKey(index);
                event.accepted = true;
            }
            background: Rectangle {
                radius: 8
                color: lightButton.baseColor
                border.width: lightButton.activeFocus ? 2 : 1
                border.color: lightButton.activeFocus ? "#c0f1d0" : lightButton.hovered ? "#8aaa96" : "#364151"
                Behavior on color {
                    enabled: view.animationAllowed
                    ColorAnimation { id: fade; duration: 140; easing.type: Easing.OutQuad }
                }
                Connections {
                    target: view
                    function onAnimationAllowedChanged(): void { if (!view.animationAllowed) fade.complete(); }
                }
            }
            contentItem: Item {
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(6, lightButton.width * 0.18)
                    height: width
                    radius: width / 2
                    color: "#c0f1d0"
                    opacity: lightButton.lit ? 1 : 0.06
                    scale: lightButton.lit ? 1 : 0.6
                    Behavior on opacity {
                        enabled: view.animationAllowed
                        NumberAnimation { id: glow; duration: 140 }
                    }
                    Behavior on scale {
                        enabled: view.animationAllowed
                        NumberAnimation { id: bloom; duration: 140; easing.type: Easing.OutQuad }
                    }
                    Connections {
                        target: view
                        function onAnimationAllowedChanged(): void {
                            if (!view.animationAllowed) { glow.complete(); bloom.complete(); }
                        }
                    }
                }
            }
        }
    }
}
