import QtQuick
import "../code/Snake.js" as Snake
import "../code/Mines.js" as Mines
import "../code/TicTacToe.js" as Tic
import "../code/Twenty48.js" as Twenty48
import "../code/Lights.js" as Lights

QtObject {
    id: controller
    property string selected: ""
    property var state: null
    property int revision: 0
    property bool interactive: false
    property int best: 0
    property bool sliding: false
    property var queuedSlides: []
    readonly property int slideDuration: 140
    readonly property string status: { revision; return state ? state.status : ""; }
    readonly property bool ended: status !== "" && status !== "playing" && status !== "paused"
    signal bestChangedByGame(int score)
    signal slideStarted(var plan)
    signal slideFinished()

    function select(game: string): void {
        if (["snake", "mines", "tic", "2048", "lights"].indexOf(game) === -1) return;
        selected = game;
        restart();
    }
    function restart(): void {
        if (!selected) return;
        finishSlide(false);
        state = selected === "snake" ? Snake.create()
              : selected === "mines" ? Mines.create() : selected === "tic" ? Tic.create()
              : selected === "2048" ? Twenty48.create() : Lights.create();
        ++revision;
    }
    function back(): void {
        finishSlide(false);
        selected = "";
        state = null;
        ++revision;
    }
    function pause(): void {
        if (selected === "snake" && status === "playing") {
            state.status = "paused";
            ++revision;
        }
    }
    function togglePause(): void {
        if (selected !== "snake" || ended) return;
        state.status = status === "paused" ? "playing" : "paused";
        ++revision;
    }
    function steer(direction: int): void { if (selected === "snake") Snake.turn(state, direction); }
    function reveal(index: int): void { if (selected === "mines") { Mines.reveal(state, index); ++revision; } }
    function flag(index: int): void { if (selected === "mines") { Mines.flag(state, index); ++revision; } }
    function move(index: int): void { if (selected === "tic") { Tic.move(state, index); ++revision; } }
    function slide(direction, repeated = false) {
        if (selected !== "2048" || status !== "playing") return;
        if (direction < 0 || direction > 3) return;
        if (sliding) {
            // Keep physical taps in order; hold repeats need only one pending move.
            if (repeated && queuedSlides.some(item => item.repeat && item.direction === direction)) return;
            if (queuedSlides.length < 8) queuedSlides = queuedSlides.concat([{direction: direction, repeat: repeated}]);
            return;
        }
        const plan = Twenty48.move(state, direction);
        sliding = plan.changed && interactive;
        ++revision;
        if (sliding) { slideStarted(plan); slideClock.restart(); }
        else if (queuedSlides.length) finishSlide(true);
    }
    function releaseSlide(direction: int): void {
        queuedSlides = queuedSlides.filter(item => !item.repeat || item.direction !== direction);
    }
    function finishSlide(drain: bool): void {
        slideClock.stop();
        const next = drain && queuedSlides.length ? queuedSlides[0] : null;
        queuedSlides = drain ? queuedSlides.slice(1) : [];
        if (sliding) { sliding = false; slideFinished(); }
        if (drain && interactive && next && selected === "2048" && status === "playing") slide(next.direction, next.repeat);
        else queuedSlides = [];
    }
    function pressLight(index: int): void { if (selected === "lights") { Lights.press(state, index); ++revision; } }
    onInteractiveChanged: { if (!interactive) { pause(); finishSlide(false); } }

    property Timer slideClock: Timer {
        interval: controller.slideDuration
        repeat: false
        onTriggered: controller.finishSlide(true)
    }

    property Timer clock: Timer {
        interval: 140
        repeat: true
        running: controller.selected === "snake" && controller.status === "playing" && controller.interactive
        onTriggered: {
            Snake.tick(controller.state);
            ++controller.revision;
            if (controller.state.score > controller.best) {
                controller.best = controller.state.score;
                controller.bestChangedByGame(controller.best);
            }
        }
    }
}
