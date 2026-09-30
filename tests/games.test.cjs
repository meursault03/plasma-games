const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const vm = require('node:vm');

function rules(name) {
    const context = vm.createContext({ Math });
    vm.runInContext(readFileSync(join(__dirname, '../package/contents/code', name + '.js'), 'utf8'), context);
    return context;
}
const Snake = rules('Snake'), Mines = rules('Mines'), Tic = rules('TicTacToe');
const Twenty48 = rules('Twenty48'), Lights = rules('Lights');
const copy = value => JSON.parse(JSON.stringify(value));
const zero = () => 0;

test('Snake moves, grows, scores and places food off the body', () => {
    const state = Snake.create(zero);
    Snake.tick(state, zero);
    assert.deepEqual(copy(state.body), [211, 210, 209]);
    state.food = 212;
    Snake.tick(state, zero);
    assert.equal(state.score, 1);
    assert.equal(state.body.length, 4);
    assert.ok(!state.body.includes(state.food));
});

test('Snake rejects reversal and accepts only one turn per tick', () => {
    const state = Snake.create(zero);
    Snake.turn(state, 3);
    assert.equal(state.pending, -1);
    Snake.turn(state, 0);
    Snake.turn(state, 3);
    Snake.tick(state, zero);
    assert.equal(state.direction, 0);
    assert.equal(state.body[0], 190);
    Snake.turn(state, 3);
    Snake.tick(state, zero);
    assert.equal(state.body[0], 189);
});

test('Snake wraps all four edges without leaking into adjacent rows', () => {
    for (const [head, direction, next] of [[39, 1, 20], [20, 3, 39], [10, 0, 390], [390, 2, 10]]) {
        const state = Snake.create(zero);
        Object.assign(state, { body: [head], direction, food: 100 });
        Snake.tick(state, zero);
        assert.equal(state.status, 'playing');
        assert.equal(state.body[0], next);
    }
});

test('Snake self-collision ends the round; paused rounds do not move', () => {
    const self = Snake.create(zero);
    Object.assign(self, { body: [21, 22, 42, 41], direction: 1, food: 100 });
    Snake.tick(self, zero);
    assert.equal(self.status, 'lost');
    const paused = Snake.create(zero);
    paused.status = 'paused';
    const before = copy(paused);
    Snake.turn(paused, 0);
    Snake.tick(paused, zero);
    assert.deepEqual(copy(paused), before);
});

test('Snake still detects collisions, growth and departing tails across edges', () => {
    const blocked = Snake.create(zero);
    Object.assign(blocked, { body: [39, 20, 21], direction: 1, food: 100 });
    Snake.tick(blocked, zero);
    assert.equal(blocked.status, 'lost');
    const tail = Snake.create(zero);
    Object.assign(tail, { body: [39, 38, 18, 19, 0, 20], direction: 1, food: 100 });
    Snake.tick(tail, zero);
    assert.equal(tail.status, 'playing');
    assert.equal(tail.body[0], 20);
    const grows = Snake.create(zero);
    Object.assign(grows, { body: [39, 38, 37], direction: 1, food: 20 });
    Snake.tick(grows, zero);
    assert.equal(grows.score, 1);
    assert.equal(grows.body.length, 4);
    assert.equal(grows.body[0], 20);
});

test('Snake may enter its departing tail and wins when the board fills', () => {
    const tail = Snake.create(zero);
    Object.assign(tail, { body: [21, 41, 42, 22], direction: 1, food: 100 });
    Snake.tick(tail, zero);
    assert.equal(tail.status, 'playing');
    assert.deepEqual(copy(tail.body), [22, 21, 41, 42]);
    const full = Snake.create(zero);
    const body = Array.from({ length: 400 }, (_, i) => i).filter(i => i !== 1);
    Object.assign(full, { body, direction: 1, food: 1 });
    Snake.tick(full, zero);
    assert.equal(full.status, 'won');
    assert.equal(full.food, -1);
    assert.equal(full.body.length, 400);
});

test('Every Minesweeper first cell and its neighbors are safe, with exactly 10 mines', () => {
    for (let first = 0; first < 81; ++first) {
        const state = Mines.create();
        Mines.reveal(state, first, zero);
        assert.equal(state.cells.filter(c => c.mine).length, 10);
        for (const safe of [first, ...Mines.neighbors(first)]) assert.equal(state.cells[safe].mine, false);
        assert.equal(state.cells[first].revealed, true);
        for (let i = 0; i < 81; ++i)
            assert.equal(state.cells[i].count, Mines.neighbors(i).filter(n => state.cells[n].mine).length);
    }
});

test('Minesweeper flags block reveal, cap at 10, and toggle before generation', () => {
    const state = Mines.create();
    for (let i = 0; i < 11; ++i) Mines.flag(state, i);
    assert.equal(state.flags, 10);
    assert.equal(state.cells[10].flagged, false);
    Mines.reveal(state, 0, zero);
    assert.equal(state.generated, false);
    Mines.flag(state, 0);
    Mines.reveal(state, 0, zero);
    assert.equal(state.generated, true);
    assert.equal(state.cells[0].revealed, true);
    const flags = state.flags;
    Mines.flag(state, 0);
    assert.equal(state.flags, flags);
});

test('Minesweeper flood fills, wins on all safe cells, and freezes after loss', () => {
    const won = Mines.create();
    Mines.reveal(won, 80, zero);
    assert.ok(won.revealed > 1);
    for (let i = 0; i < 81; ++i) if (!won.cells[i].mine) Mines.reveal(won, i, zero);
    assert.equal(won.revealed, 71);
    assert.equal(won.status, 'won');
    const lost = Mines.create();
    Mines.generate(lost, 40, zero);
    Mines.reveal(lost, lost.cells.findIndex(c => c.mine), zero);
    assert.equal(lost.status, 'lost');
    const before = copy(lost);
    Mines.flag(lost, 80);
    Mines.reveal(lost, 80, zero);
    assert.deepEqual(copy(lost), before);
});

test('Tic-tac-toe detects winning lines and draws; occupied cells are inert', () => {
    assert.equal(Tic.result(['X', 'X', 'X', '', '', '', '', '', '']), 'X');
    assert.equal(Tic.result(['O', '', '', '', 'O', '', '', '', 'O']), 'O');
    assert.equal(Tic.result(['X', 'O', 'X', 'X', 'O', 'O', 'O', 'X', 'X']), 'draw');
    const state = Tic.create();
    Tic.move(state, 0);
    assert.equal(state.board.filter(c => c === 'O').length, 1);
    const before = copy(state);
    Tic.move(state, 0);
    assert.deepEqual(copy(state), before);
});

test('Tic-tac-toe computer never loses across every possible human continuation', () => {
    let endings = 0;
    function explore(state) {
        if (state.status !== 'playing') {
            assert.notEqual(state.status, 'X');
            ++endings;
            return;
        }
        for (let i = 0; i < 9; ++i) {
            if (state.board[i]) continue;
            const next = copy(state);
            Tic.move(next, i);
            explore(next);
        }
    }
    explore(Tic.create());
    assert.ok(endings > 100);
});

test('All games create independent, fresh rounds', () => {
    for (const game of [Snake, Mines, Tic, Twenty48, Lights]) {
        const first = game.create(zero), second = game.create(zero);
        first.status = 'lost';
        assert.equal(second.status, 'playing');
        assert.equal(game.create(zero).status, 'playing');
    }
});

test('2048 merges each tile at most once per move and updates the score', () => {
    const state = { tiles: [2, 2, 2, 2, ...Array(12).fill(0)], score: 0, status: 'playing' };
    Twenty48.move(state, 3, () => 0.99);
    assert.deepEqual(state.tiles.slice(0, 4), [4, 4, 0, 0]);
    assert.equal(state.score, 8);
    assert.equal(state.tiles[15], 2);
    Twenty48.move(state, 3, () => 0.99);
    assert.deepEqual(state.tiles.slice(0, 4), [8, 0, 0, 0]);
    assert.equal(state.score, 16);
});

test('2048 slides correctly in all four directions; no-op moves do not spawn', () => {
    for (const [direction, expected] of [[0, 1], [1, 7], [2, 13], [3, 4]]) {
        const state = { tiles: Array(16).fill(0), score: 0, status: 'playing' };
        state.tiles[5] = 2;
        Twenty48.move(state, direction, () => 0.99);
        assert.equal(state.tiles[expected], 2);
        assert.equal(state.tiles.filter(Boolean).length, 2);
        assert.equal(state.score, 0);
    }
    const state = { tiles: [2, ...Array(15).fill(0)], score: 0, status: 'playing' };
    const before = copy(state);
    Twenty48.move(state, 3, () => { throw Error('No-op must not spawn'); });
    assert.deepEqual(state, before);
});

test('2048 detects a blocked board, available merges, and winning tiles', () => {
    const blocked = { tiles: [2,4,2,4, 4,2,4,2, 2,4,2,4, 4,2,4,2], score: 0, status: 'playing' };
    assert.equal(Twenty48.canMove(blocked.tiles), false);
    Twenty48.move(blocked, 0, zero);
    assert.equal(blocked.status, 'lost');
    blocked.tiles[0] = 4;
    assert.equal(Twenty48.canMove(blocked.tiles), true);
    const winning = { tiles: [1024,1024,...Array(14).fill(0)], score: 0, status: 'playing' };
    Twenty48.move(winning, 3, zero);
    assert.equal(winning.status, 'won');
    assert.equal(winning.score, 2048);
    assert.equal(winning.tiles[0], 2048);
    const before = copy(winning);
    Twenty48.move(winning, 2, zero);
    assert.deepEqual(winning, before);
});

test('2048 starts with exactly two tiles and preserves the total except new spawns', () => {
    const state = Twenty48.create(() => 0.5);
    assert.equal(state.tiles.filter(Boolean).length, 2);
    assert.equal(state.tiles.reduce((a, b) => a + b), 4);
    Twenty48.move(state, 3, () => 0.5);
    assert.equal(state.tiles.reduce((a, b) => a + b), 6);
});

test('2048 animation plans account for each source tile and match the final board', () => {
    let seed = 391;
    const rng = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
    for (let sample = 0; sample < 200; ++sample) {
        const before = Array.from({ length: 16 }, () => rng() < 0.3 ? 0 : 2 ** (1 + Math.floor(rng() * 5)));
        for (let direction = 0; direction < 4; ++direction) {
            const state = { tiles: before.slice(), score: 0, status: 'playing' };
            const plan = Twenty48.move(state, direction, rng);
            const sources = new Set();
            const rebuilt = Array(16).fill(0);
            for (const motion of plan.motions) {
                assert.ok(!sources.has(motion.from));
                sources.add(motion.from);
                assert.equal(motion.value, before[motion.from]);
                assert.ok(motion.to >= 0 && motion.to < 16);
                if (!motion.consumed) {
                    assert.equal(rebuilt[motion.to], 0);
                    rebuilt[motion.to] = motion.result;
                }
            }
            assert.equal(sources.size, before.filter(Boolean).length);
            if (plan.spawn) {
                assert.equal(rebuilt[plan.spawn.cell], 0);
                rebuilt[plan.spawn.cell] = plan.spawn.value;
            }
            assert.deepEqual(rebuilt, state.tiles);
        }
    }
});

test('Lights Out toggles only orthogonal neighbors, counts moves, and freezes on win', () => {
    const state = { cells: Array(25).fill(false), moves: 0, status: 'playing' };
    Lights.press(state, 0);
    assert.deepEqual(state.cells.map((on, i) => on ? i : -1).filter(i => i >= 0), [0, 1, 5]);
    assert.equal(state.moves, 1);
    Lights.press(state, 0);
    assert.equal(state.status, 'won');
    assert.equal(state.moves, 2);
    const before = copy(state);
    Lights.press(state, 1);
    assert.deepEqual(state, before);
});

test('Lights Out generation is nonempty and solvable by reversing the scramble', () => {
    for (let seed = 1; seed <= 40; ++seed) {
        const selected = [];
        let cursor = 0;
        const state = Lights.create(() => {
            const value = ((cursor * 17 + seed * 13) % 101) / 101;
            if (value < 0.5) selected.push(cursor);
            ++cursor;
            return value;
        });
        assert.ok(state.cells.some(Boolean));
        for (const index of selected) Lights.press(state, index);
        assert.equal(state.status, 'won');
        assert.ok(state.cells.every(value => !value));
    }
    const fallback = Lights.create(() => 0.99);
    assert.ok(fallback.cells.some(Boolean));
    Lights.press(fallback, 12);
    assert.equal(fallback.status, 'won');
});
