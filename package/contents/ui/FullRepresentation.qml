pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

FocusScope {
    id: popup
    required property var controller
    required property bool expanded
    readonly property bool windowActive: Window.window ? Window.window.active : false
    readonly property string title: controller.selected === "snake" ? "Snake"
                                 : controller.selected === "mines" ? "Minesweeper"
                                 : controller.selected === "tic" ? "Tic-tac-toe"
                                 : controller.selected === "2048" ? "2048" : "Lights Out"
    signal interactiveChangedByView(bool active)
    Layout.minimumWidth: 260
    Layout.minimumHeight: 350
    Layout.preferredWidth: 400
    Layout.preferredHeight: controller.selected ? 496 : 420
    focus: true

    function reportFocus(): void { interactiveChangedByView(expanded && activeFocus && windowActive); }
    onActiveFocusChanged: reportFocus()
    onWindowActiveChanged: reportFocus()
    onExpandedChanged: {
        if (expanded) forceActiveFocus();
        reportFocus();
    }
    Component.onCompleted: { if (expanded) forceActiveFocus(); reportFocus(); }
    Component.onDestruction: interactiveChangedByView(false)

    function choose(game: string): void { forceActiveFocus(); controller.select(game); reportFocus(); }
    Keys.onPressed: event => {
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && controller.ended) {
            controller.restart(); popup.forceActiveFocus(); event.accepted = true;
        } else if (controller.selected === "snake" || controller.selected === "2048") {
            const keys = [Qt.Key_Up, Qt.Key_Right, Qt.Key_Down, Qt.Key_Left];
            const letters = [Qt.Key_W, Qt.Key_D, Qt.Key_S, Qt.Key_A];
            let direction = keys.indexOf(event.key);
            if (direction < 0) direction = letters.indexOf(event.key);
            if (direction >= 0) {
                if (controller.selected === "2048") controller.slide(direction, event.isAutoRepeat);
                else if (!event.isAutoRepeat) controller.steer(direction);
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Space && controller.selected === "snake") {
                if (!event.isAutoRepeat) controller.togglePause();
                event.accepted = true;
            }
        }
    }
    Keys.onReleased: event => {
        if (controller.selected !== "2048" || event.isAutoRepeat) return;
        const keys = [Qt.Key_Up, Qt.Key_Right, Qt.Key_Down, Qt.Key_Left];
        const letters = [Qt.Key_W, Qt.Key_D, Qt.Key_S, Qt.Key_A];
        let direction = keys.indexOf(event.key);
        if (direction < 0) direction = letters.indexOf(event.key);
        if (direction >= 0) { controller.releaseSlide(direction); event.accepted = true; }
    }

    Rectangle { anchors.fill: parent; color: "#191e26"; radius: 12 }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: 44
            Layout.maximumHeight: 44
            DarkButton {
                visible: popup.controller.selected !== ""
                text: "‹"
                Accessible.name: "Back to games"
                implicitWidth: 40
                Keys.forwardTo: popup.controller.selected === "2048" ? [popup] : []
                onClicked: { popup.controller.back(); popup.forceActiveFocus(); }
            }
            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                text: popup.controller.selected ? popup.title : "Plasma Games"
                elide: Text.ElideRight
                color: "#e6e9ee"
                font.pixelSize: 21
                font.weight: Font.DemiBold
            }
            Text {
                visible: popup.controller.selected === "snake" || popup.controller.selected === "2048"
                Layout.alignment: Qt.AlignVCenter
                text: {
                    popup.controller.revision;
                    if (!popup.controller.state) return "";
                    if (popup.controller.selected === "snake") return popup.controller.state.score + " / " + popup.controller.best + " best";
                    return popup.controller.selected === "2048" ? String(popup.controller.state.score) : "";
                }
                color: "#a5afbe"
                font.pixelSize: 12
            }
        }
        ColumnLayout {
            visible: popup.controller.selected === ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            DarkButton { Layout.fillWidth: true; Layout.minimumHeight: 40; text: "Snake"; onClicked: popup.choose("snake") }
            DarkButton { Layout.fillWidth: true; Layout.minimumHeight: 40; text: "Minesweeper"; onClicked: popup.choose("mines") }
            DarkButton { Layout.fillWidth: true; Layout.minimumHeight: 40; text: "Tic-tac-toe"; onClicked: popup.choose("tic") }
            DarkButton { Layout.fillWidth: true; Layout.minimumHeight: 40; text: "2048"; onClicked: popup.choose("2048") }
            DarkButton { Layout.fillWidth: true; Layout.minimumHeight: 40; text: "Lights Out"; onClicked: popup.choose("lights") }
            Item { Layout.fillHeight: true }
        }
        Item {
            visible: popup.controller.selected !== ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            Loader {
                id: board
                objectName: "gameBoard"
                anchors.centerIn: parent
                readonly property int gridSize: popup.controller.selected === "snake" ? 20 : popup.controller.selected === "mines" ? 9
                                                  : popup.controller.selected === "tic" ? 3 : popup.controller.selected === "2048" ? 4 : 5
                width: Math.floor(Math.max(0, Math.min(parent.width, parent.height)) / gridSize) * gridSize
                height: width
                clip: true
                active: popup.controller.selected !== ""
                sourceComponent: popup.controller.selected === "snake" ? snakeComponent : popup.controller.selected === "mines" ? minesComponent
                               : popup.controller.selected === "tic" ? ticComponent : popup.controller.selected === "2048" ? twenty48Component : lightsComponent
            }
            Rectangle {
                anchors.fill: board
                visible: popup.controller.status === "paused"
                color: "#dc11161d"
                radius: 8
                DarkButton {
                    anchors.centerIn: parent
                    text: "Resume"
                    onClicked: { popup.forceActiveFocus(); popup.controller.togglePause(); }
                }
            }
        }
        RowLayout {
            visible: popup.controller.selected !== ""
            Layout.fillWidth: true
            Layout.minimumHeight: 44
            Layout.maximumHeight: 44
            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: popup.controller.ended ? "#e6e9ee" : "#a5afbe"
                font.pixelSize: 12
                text: {
                    popup.controller.revision;
                    if (popup.controller.ended) {
                        if (popup.controller.selected === "tic") return popup.controller.status === "draw" ? "A draw. Well played." : popup.controller.status === "O" ? "Computer wins." : "You win!";
                        return popup.controller.status === "won" ? "You win!" : "Game over.";
                    }
                    if (popup.controller.selected === "mines") return popup.controller.state ? (10 - popup.controller.state.flags) + " mines left · Click to reveal · Right-click / F to flag" : "";
                    if (popup.controller.selected === "tic") return "Your turn · You are X";
                    if (popup.controller.selected === "2048") return "Arrows / WASD or swipe · Reach 2048";
                    if (popup.controller.selected === "lights") return popup.controller.state ? popup.controller.state.moves + " moves · Click toggles neighbors · Turn all off" : "";
                    return "Arrows / WASD · Space to pause · Edges wrap";
                }
            }
            DarkButton {
                visible: popup.controller.ended
                Layout.alignment: Qt.AlignVCenter
                text: "Play Again"
                onClicked: { popup.forceActiveFocus(); popup.controller.restart(); }
            }
        }
    }
    Component { id: snakeComponent; SnakeView { controller: popup.controller } }
    Component { id: minesComponent; MinesView { controller: popup.controller } }
    Component { id: ticComponent; TicView { controller: popup.controller } }
    Component { id: twenty48Component; Twenty48View { controller: popup.controller } }
    Component { id: lightsComponent; LightsView { controller: popup.controller } }
}
