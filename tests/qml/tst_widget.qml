import QtQuick
import QtTest
import "../../package/contents/ui" as Games

Item {
    width: 400
    height: 496
    Games.GameController { id: controller }
    Games.GameController { id: otherController }
    Games.PanelIcon { id: panelIcon; visible: false }
    SignalSpy { id: iconSpy; target: panelIcon; signalName: "activated" }
    SignalSpy { id: bestSpy; target: controller; signalName: "bestChangedByGame" }
    SignalSpy { id: slideSpy; target: controller; signalName: "slideStarted" }
    Games.FullRepresentation {
        id: popup
        anchors.fill: parent
        controller: controller
        expanded: true
        onInteractiveChangedByView: active => { controller.interactive = active; }
    }
    TestCase {
        name: "Widget"
        when: windowShown
        function init() { controller.back(); otherController.back(); bestSpy.clear(); slideSpy.clear(); }
        function test_all_views_and_restart() {
            for (const game of ["snake", "mines", "tic", "2048", "lights"]) {
                popup.choose(game);
                wait(20);
                compare(controller.selected, game);
                compare(controller.status, "playing");
                if (game === "mines") { controller.reveal(40); verify(controller.state.generated); }
                if (game === "tic") { controller.move(0); compare(controller.state.board[0], "X"); }
                controller.restart();
                compare(controller.status, "playing");
                controller.back();
                wait(20);
                compare(controller.state, null);
            }
        }
        function test_snake_timer_pause_and_retention() {
            controller.select("snake");
            controller.interactive = true;
            const first = controller.state.body[0];
            tryVerify(() => controller.state.body[0] !== first, 500);
            controller.interactive = false;
            compare(controller.status, "paused");
            const paused = controller.state.body[0];
            wait(300);
            compare(controller.state.body[0], paused);
            controller.interactive = true;
            wait(180);
            compare(controller.state.body[0], paused);
            controller.togglePause();
            tryVerify(() => controller.state.body[0] !== paused, 500);
        }
        function test_mines_bindings_update() {
            popup.choose("mines");
            wait(20);
            controller.flag(0);
            wait(20);
            verify(findFlag(popup));
            controller.flag(0);
            controller.reveal(40);
            wait(20);
            verify(controller.state.cells[40].revealed);
        }
        function test_finished_board_keeps_its_size() {
            for (const game of ["mines", "tic", "lights"]) {
                popup.choose(game);
                wait(40);
                const view = findCell(popup, 0).parent;
                const size = view.width;
                const origin = view.mapToItem(popup, 0, 0);
                controller.state.status = game === "tic" ? "draw" : "lost";
                ++controller.revision;
                wait(40);
                compare(view.width, size, "Board must not shrink when Play Again appears");
                const after = view.mapToItem(popup, 0, 0);
                compare(after.x, origin.x);
                compare(after.y, origin.y);
            }
        }
        function test_right_click_focuses_the_flagged_cell() {
            popup.choose("mines");
            wait(40);
            const cell = findCell(popup, 3);
            mouseClick(cell, cell.width / 2, cell.height / 2, Qt.RightButton);
            verify(cell.activeFocus);
            keyClick(Qt.Key_F);
            verify(!controller.state.cells[3].flagged);
        }
        function test_pointer_and_keyboard_controls() {
            const select = findText(popup, "Minesweeper");
            verify(select !== null);
            mouseClick(select);
            wait(20);
            const first = findCell(popup, 0);
            verify(first !== null);
            mouseClick(first, first.width / 2, first.height / 2, Qt.RightButton);
            compare(controller.state.flags, 1);
            compare(first.text, "⚑");
            mouseClick(first);
            verify(!controller.state.generated);
            first.forceActiveFocus();
            keyClick(Qt.Key_F);
            compare(controller.state.flags, 0);
            keyClick(Qt.Key_Space);
            verify(controller.state.generated);
            verify(controller.state.cells[0].revealed);
            popup.choose("tic");
            wait(20);
            mouseClick(findCell(popup, 0));
            compare(controller.state.board[0], "X");
            popup.choose("snake");
            keyClick(Qt.Key_Up);
            compare(controller.state.pending, 0);
            keyClick(Qt.Key_Space);
            compare(controller.status, "paused");
            mouseClick(findText(popup, "Resume"));
            compare(controller.status, "playing");
        }
        function test_close_and_reopen_require_resume() {
            popup.choose("snake");
            wait(20);
            popup.expanded = false;
            compare(controller.status, "paused");
            verify(!controller.clock.running);
            const head = controller.state.body[0];
            popup.expanded = true;
            wait(180);
            compare(controller.status, "paused");
            compare(controller.state.body[0], head);
        }
        function test_best_score_and_instance_isolation() {
            controller.best = 0;
            controller.select("snake");
            otherController.select("snake");
            controller.state.food = controller.state.body[0] + 1;
            controller.interactive = true;
            tryCompare(controller, "best", 1, 500);
            compare(bestSpy.count, 1);
            compare(bestSpy.signalArguments[0][0], 1);
            compare(otherController.state.score, 0);
            compare(otherController.best, 0);
            controller.restart();
            compare(controller.state.score, 0);
            compare(controller.best, 1);
        }
        function test_new_games_controls_and_idle_timers() {
            popup.choose("2048");
            controller.state.tiles = [2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            ++controller.revision;
            keyClick(Qt.Key_Left);
            compare(controller.state.tiles[0], 4);
            compare(controller.state.score, 4);
            verify(!controller.clock.running);
            popup.choose("lights");
            wait(30);
            const first = findCell(popup, 0);
            const original = controller.state.cells[0];
            mouseClick(first);
            compare(controller.state.cells[0], !original);
            compare(controller.state.moves, 1);
            verify(!controller.clock.running);
            const before = JSON.stringify(controller.state);
            popup.expanded = false;
            popup.expanded = true;
            compare(JSON.stringify(controller.state), before);
        }
        function test_controller_rejects_stale_actions() {
            controller.restart();
            compare(controller.state, null);
            controller.select("unknown");
            compare(controller.selected, "");
            controller.select("tic");
            controller.reveal(0);
            controller.flag(0);
            controller.slide(0);
            controller.pressLight(0);
            compare(controller.state.board[0], "");
        }
        function test_lit_light_stays_green_on_hover() {
            popup.choose("lights");
            controller.state.cells[0] = true;
            ++controller.revision;
            wait(30);
            const cell = findCell(popup, 0);
            mouseMove(cell, cell.width / 2, cell.height / 2);
            tryVerify(() => cell.hovered);
            tryCompare(cell.background, "color", cell.baseColor);
            verify(cell.background.color.g > cell.background.color.b);
            verify(cell.lit);
        }
        function test_panel_icon_is_white_square_and_centered() {
            panelIcon.visible = true;
            for (const size of [[32, 40], [40, 32], [16, 16], [64, 64]]) {
                panelIcon.width = size[0];
                panelIcon.height = size[1];
                wait(20);
                const glyph = findChild(panelIcon, "panelGlyph");
                verify(glyph !== null);
                compare(glyph.width, glyph.height);
                verify(glyph.width <= 22);
                fuzzyCompare(glyph.x + glyph.width / 2, panelIcon.width / 2, 0.01);
                fuzzyCompare(glyph.y + glyph.height / 2, panelIcon.height / 2, 0.01);
                compare(glyph.color, "#ffffff");
                verify(glyph.source.toString().endsWith("/images/games.svg"));
            }
            iconSpy.clear();
            mouseClick(panelIcon);
            compare(iconSpy.count, 1);
            panelIcon.forceActiveFocus();
            keyClick(Qt.Key_Return);
            compare(iconSpy.count, 2);
            panelIcon.visible = false;
            popup.forceActiveFocus();
        }
        function prepare2048() {
            popup.choose("2048");
            controller.state.tiles = [2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            ++controller.revision;
            controller.interactive = true;
            wait(30);
            return findChild(popup, "gameBoard").item;
        }
        function verifyVisualBoard(view) {
            const rendered = new Array(16).fill(0);
            verify(view.visualTiles.count <= 16);
            for (let i = 0; i < view.visualTiles.count; ++i) {
                const tile = view.visualTiles.get(i);
                compare(rendered[tile.cell], 0, "A settled cell must contain exactly one tile");
                rendered[tile.cell] = tile.value;
            }
            compare(JSON.stringify(rendered), JSON.stringify(controller.state.tiles));
        }
        function test_2048_tiles_move_then_merge_without_ghosts() {
            const view = prepare2048();
            controller.slide(3);
            verify(controller.sliding);
            compare(view.visualTiles.count, 4);
            let moving = null;
            for (const child of view.children)
                if (child.objectName === "movingTile" && child.consumed && child.cell === 0) moving = child;
            verify(moving !== null);
            wait(45);
            verify(moving.x > 3 && moving.x < view.width / 4 + 3, "Tile should visibly travel between cells");
            tryCompare(controller, "sliding", false, 500);
            verifyVisualBoard(view);
            compare(controller.state.score, 8);
        }
        function test_2048_rapid_taps_are_queued_once_in_order() {
            const view = prepare2048();
            keyClick(Qt.Key_Left);
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Right);
            compare(controller.queuedSlides.length, 2);
            tryVerify(() => !controller.sliding && controller.queuedSlides.length === 0, 1500);
            compare(slideSpy.count, 3);
            verifyVisualBoard(view);
        }
        function test_2048_hold_repeat_queue_stops_on_release() {
            prepare2048();
            controller.slide(3);
            for (let i = 0; i < 20; ++i) controller.slide(2, true);
            compare(controller.queuedSlides.length, 1);
            controller.releaseSlide(2);
            compare(controller.queuedSlides.length, 0);
            tryCompare(controller, "sliding", false, 500);
            compare(slideSpy.count, 1);
        }
        function test_2048_swipe_and_winning_merge() {
            const view = prepare2048();
            mousePress(view, view.width * 0.8, view.height / 2);
            mouseMove(view, view.width * 0.2, view.height / 2);
            mouseRelease(view, view.width * 0.2, view.height / 2);
            compare(slideSpy.count, 1);
            tryCompare(controller, "sliding", false, 500);
            verifyVisualBoard(view);
            mouseClick(view);
            compare(slideSpy.count, 1, "A plain click only focuses the board");
            controller.state.tiles = [1024, 1024, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            ++controller.revision;
            keyClick(Qt.Key_Left);
            compare(controller.status, "won");
            tryCompare(controller, "sliding", false, 500);
            verifyVisualBoard(view);
            compare(view.visualTiles.count, 1);
            compare(view.visualTiles.get(0).value, 2048);
        }
        function test_2048_focus_close_restart_and_resize() {
            const view = prepare2048();
            findText(popup, "‹").forceActiveFocus();
            keyClick(Qt.Key_Right);
            verify(controller.sliding);
            compare(slideSpy.count, 1);
            controller.slide(2);
            popup.expanded = false;
            verify(!controller.sliding);
            verify(!controller.slideClock.running);
            compare(controller.queuedSlides.length, 0);
            verifyVisualBoard(view);
            const before = JSON.stringify(controller.state.tiles);
            popup.expanded = true;
            wait(180);
            compare(JSON.stringify(controller.state.tiles), before);
            controller.slide(0);
            controller.restart();
            compare(controller.state.score, 0);
            verify(!controller.sliding);
            compare(controller.queuedSlides.length, 0);
            verifyVisualBoard(view);
            controller.state.tiles = [2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            ++controller.revision;
            controller.slide(3);
            popup.parent.width = 360;
            wait(40);
            verify(!controller.sliding);
            verifyVisualBoard(view);
            popup.parent.width = 400;
        }
        function test_lights_each_mouse_or_key_action_toggles_once() {
            popup.choose("lights");
            controller.state.cells = new Array(25).fill(true);
            ++controller.revision;
            wait(30);
            const cell = findCell(popup, 0);
            mouseClick(cell);
            compare(controller.state.moves, 1);
            verify(!controller.state.cells[0]);
            cell.forceActiveFocus();
            keyClick(Qt.Key_Return);
            compare(controller.state.moves, 2);
            verify(controller.state.cells[0]);
            keyClick(Qt.Key_Space);
            compare(controller.state.moves, 3);
            verify(!controller.state.cells[0]);
            for (let i = 0; i < 8; ++i) {
                mouseClick(cell);
                compare(controller.state.moves, 4 + i);
            }
            wait(200);
            compare(cell.lit, controller.state.cells[0]);
            compare(cell.background.color, cell.baseColor);
            popup.expanded = false;
            popup.expanded = true;
            compare(controller.state.moves, 11);
        }
        function test_lights_focused_enter_restarts_after_win() {
            popup.choose("lights");
            controller.state.cells = new Array(25).fill(false);
            controller.state.cells[0] = controller.state.cells[1] = controller.state.cells[5] = true;
            ++controller.revision;
            wait(30);
            findCell(popup, 0).forceActiveFocus();
            keyClick(Qt.Key_Return);
            compare(controller.state.moves, 1);
            compare(controller.status, "won");
            keyClick(Qt.Key_Return);
            compare(controller.state.moves, 0);
            compare(controller.status, "playing");
        }
        function findText(item, text) {
            if (item.text === text && item.clicked !== undefined) return item;
            for (const child of item.children) {
                const found = findText(child, text);
                if (found) return found;
            }
            return null;
        }
        function findCell(item, index) {
            if (item.index === index && item.clicked !== undefined) return item;
            for (const child of item.children) {
                const found = findCell(child, index);
                if (found) return found;
            }
            return null;
        }
        function findFlag(item) {
            if (item.text === "⚑") return true;
            for (const child of item.children) if (findFlag(child)) return true;
            return false;
        }
    }
}
