function spawn(state, random) {
    var empty = [];
    for (var i = 0; i < 16; ++i) if (!state.tiles[i]) empty.push(i);
    if (!empty.length) return null;
    var cell = empty[Math.floor(random() * empty.length)];
    state.tiles[cell] = random() < 0.1 ? 4 : 2;
    return { cell: cell, value: state.tiles[cell] };
}

function create(random) {
    var state = { tiles: new Array(16).fill(0), score: 0, status: "playing" };
    spawn(state, random || Math.random);
    spawn(state, random || Math.random);
    return state;
}

function canMove(tiles) {
    for (var i = 0; i < 16; ++i)
        if (!tiles[i] || (i % 4 < 3 && tiles[i] === tiles[i + 1])
                || (i < 12 && tiles[i] === tiles[i + 4])) return true;
    return false;
}

// Same clockwise direction convention as Snake.
function move(state, direction, random) {
    var plan = { changed: false, motions: [], spawn: null };
    if (state.status !== "playing" || direction < 0 || direction > 3) return plan;
    var changed = false;
    for (var line = 0; line < 4; ++line) {
        var indices = [], values = [], sources = [], merged = [];
        for (var p = 0; p < 4; ++p) {
            var index = direction === 0 ? p * 4 + line : direction === 2 ? (3 - p) * 4 + line
                      : direction === 3 ? line * 4 + p : line * 4 + 3 - p;
            indices.push(index);
            if (state.tiles[index]) { values.push(state.tiles[index]); sources.push(index); }
        }
        for (var v = 0; v < values.length; ++v) {
            var value = values[v];
            var destination = indices[merged.length];
            var first = { from: sources[v], to: destination, value: value, result: value, consumed: false };
            if (v + 1 < values.length && value === values[v + 1]) {
                value *= 2;
                state.score += value;
                first.result = value;
                plan.motions.push({ from: sources[v + 1], to: destination, value: values[v + 1], result: value, consumed: true });
                ++v;
            }
            plan.motions.push(first);
            merged.push(value);
        }
        for (var j = 0; j < 4; ++j) {
            var next = merged[j] || 0;
            if (state.tiles[indices[j]] !== next) changed = true;
            state.tiles[indices[j]] = next;
        }
    }
    plan.changed = changed;
    if (state.tiles.indexOf(2048) !== -1) { state.status = "won"; return plan; }
    if (changed) plan.spawn = spawn(state, random || Math.random);
    if (!canMove(state.tiles)) state.status = "lost";
    return plan;
}
