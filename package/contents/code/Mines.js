function neighbors(index) {
    var result = [], x = index % 9, y = Math.floor(index / 9);
    for (var dy = -1; dy <= 1; ++dy)
        for (var dx = -1; dx <= 1; ++dx)
            if ((dx || dy) && x + dx >= 0 && x + dx < 9 && y + dy >= 0 && y + dy < 9)
                result.push((y + dy) * 9 + x + dx);
    return result;
}

function create() {
    var cells = [];
    for (var i = 0; i < 81; ++i)
        cells.push({ mine: false, count: 0, revealed: false, flagged: false });
    return { cells: cells, generated: false, flags: 0, revealed: 0, status: "playing" };
}

function generate(state, first, random) {
    var safe = neighbors(first).concat([first]), candidates = [];
    for (var i = 0; i < 81; ++i)
        if (safe.indexOf(i) === -1) candidates.push(i);
    for (var n = 0; n < 10; ++n) {
        var chosen = Math.floor(random() * candidates.length);
        state.cells[candidates.splice(chosen, 1)[0]].mine = true;
    }
    for (var c = 0; c < 81; ++c)
        state.cells[c].count = neighbors(c).filter(function (i) { return state.cells[i].mine; }).length;
    state.generated = true;
}

function flag(state, index) {
    var cell = state.cells[index];
    if (state.status !== "playing" || !cell || cell.revealed) return;
    if (!cell.flagged && state.flags === 10) return;
    cell.flagged = !cell.flagged;
    state.flags += cell.flagged ? 1 : -1;
}

function reveal(state, index, random) {
    var cell = state.cells[index];
    if (state.status !== "playing" || !cell || cell.revealed || cell.flagged) return;
    if (!state.generated) generate(state, index, random || Math.random);
    if (cell.mine) {
        cell.revealed = true;
        state.status = "lost";
        return;
    }
    var queue = [index];
    while (queue.length) {
        var current = queue.pop(), target = state.cells[current];
        if (target.revealed || target.flagged || target.mine) continue;
        target.revealed = true;
        ++state.revealed;
        if (!target.count) queue = queue.concat(neighbors(current));
    }
    if (state.revealed === 71) state.status = "won";
}
