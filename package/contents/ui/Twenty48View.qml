pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models

Item {
    id: view
    required property var controller
    property bool animatePositions: false
    property var pendingPlan: null
    readonly property bool animationAllowed: visible && controller.interactive
    property alias visualTiles: tileModel
    signal snapAllMotion()

    function syncBoard(): void {
        animatePositions = false;
        pendingPlan = null;
        tileModel.clear();
        const state = controller.state;
        if (!state || !state.tiles) return;
        for (let cell = 0; cell < 16; ++cell)
            if (state.tiles[cell]) addTile(cell, state.tiles[cell], false);
    }
    function addTile(cell: int, value: int, born: bool): void {
        tileModel.append({cell: cell, value: value, nextValue: value, consumed: false, born: born});
    }
    function animateMove(plan: var): void {
        const sources = {};
        for (let i = 0; i < tileModel.count; ++i) sources[tileModel.get(i).cell] = i;
        // A restored/recreated view may have missed the start of a move.
        for (const motion of plan.motions)
            if (sources[motion.from] === undefined) { syncBoard(); return; }
        pendingPlan = plan;
        animatePositions = animationAllowed;
        for (const motion of plan.motions) {
            const row = sources[motion.from];
            tileModel.setProperty(row, "nextValue", motion.result);
            tileModel.setProperty(row, "consumed", motion.consumed);
            tileModel.setProperty(row, "cell", motion.to);
        }
    }
    function settle(): void {
        if (!pendingPlan) { syncBoard(); return; }
        animatePositions = false;
        snapAllMotion();
        for (let i = tileModel.count - 1; i >= 0; --i) {
            if (tileModel.get(i).consumed) tileModel.remove(i);
            else tileModel.setProperty(i, "value", tileModel.get(i).nextValue);
        }
        const spawn = pendingPlan.spawn;
        pendingPlan = null;
        if (spawn) addTile(spawn.cell, spawn.value, true);
    }
    function settleResize(): void {
        if (controller && controller.selected === "2048" && controller.sliding) controller.finishSlide(false);
    }
    onWidthChanged: settleResize()
    onHeightChanged: settleResize()
    Component.onCompleted: syncBoard()

    ListModel { id: tileModel }
    Connections {
        target: view.controller
        function onStateChanged(): void { view.syncBoard(); }
        function onRevisionChanged(): void { if (!view.controller.sliding) view.syncBoard(); }
        function onSlideStarted(plan: var): void { view.animateMove(plan); }
        function onSlideFinished(): void { view.settle(); }
    }
    Repeater {
        model: 16
        Rectangle {
            required property int index
            x: (index % 4) * view.width / 4 + 3
            y: Math.floor(index / 4) * view.height / 4 + 3
            width: view.width / 4 - 6
            height: view.height / 4 - 6
            radius: 8
            color: "#222933"
        }
    }
    Repeater {
        id: tileRepeater
        model: tileModel
        Rectangle {
            id: tile
            required property int cell
            required property int value
            required property bool consumed
            required property bool born
            property bool initialized: false
            objectName: "movingTile"
            x: (cell % 4) * view.width / 4 + 3
            y: Math.floor(cell / 4) * view.height / 4 + 3
            width: view.width / 4 - 6
            height: view.height / 4 - 6
            z: consumed ? 2 : 1
            radius: 8
            color: value >= 128 ? "#396149" : value >= 16 ? "#334b61" : "#2c3745"
            border.color: "#425062"
            border.width: 1
            Accessible.role: Accessible.StaticText
            Accessible.name: String(value)
            Behavior on x {
                enabled: view.animatePositions && view.animationAllowed
                NumberAnimation { id: motionX; duration: view.controller.slideDuration; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                enabled: view.animatePositions && view.animationAllowed
                NumberAnimation { id: motionY; duration: view.controller.slideDuration; easing.type: Easing.OutCubic }
            }
            function snapMotion(): void { motionX.complete(); motionY.complete(); }
            onValueChanged: { if (initialized && view.animationAllowed) mergePulse.restart(); }
            Component.onCompleted: {
                initialized = true;
                if (born && view.animationAllowed) spawnPulse.start();
            }
            Connections {
                target: view
                function onSnapAllMotion(): void { tile.snapMotion(); }
                function onAnimationAllowedChanged(): void {
                    if (!view.animationAllowed) {
                        tile.snapMotion();
                        mergePulse.stop(); spawnPulse.stop();
                        tile.scale = 1; tile.opacity = 1;
                    }
                }
            }
            SequentialAnimation {
                id: mergePulse
                NumberAnimation { target: tile; property: "scale"; to: 1.08; duration: 65; easing.type: Easing.OutQuad }
                NumberAnimation { target: tile; property: "scale"; to: 1; duration: 85; easing.type: Easing.OutQuad }
            }
            ParallelAnimation {
                id: spawnPulse
                NumberAnimation { target: tile; property: "scale"; from: 0.72; to: 1; duration: 110; easing.type: Easing.OutCubic }
                NumberAnimation { target: tile; property: "opacity"; from: 0; to: 1; duration: 100 }
            }
            Text {
                anchors.fill: parent
                text: tile.value
                color: "#e6e9ee"
                font.pixelSize: Math.max(14, tile.width * (tile.value >= 1000 ? 0.27 : 0.36))
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        property real startX: 0
        property real startY: 0
        onPressed: mouse => {
            view.forceActiveFocus();
            startX = mouse.x; startY = mouse.y;
        }
        onReleased: mouse => {
            const dx = mouse.x - startX, dy = mouse.y - startY;
            if (Math.max(Math.abs(dx), Math.abs(dy)) < 24) return;
            view.controller.slide(Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 1 : 3) : (dy > 0 ? 2 : 0));
        }
    }
}
