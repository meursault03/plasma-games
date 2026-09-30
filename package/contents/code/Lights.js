function toggle(cells, index) {
    var targets = [index];
    if (index >= 5) targets.push(index - 5);
    if (index < 20) targets.push(index + 5);
    if (index % 5 > 0) targets.push(index - 1);
    if (index % 5 < 4) targets.push(index + 1);
    for (var i = 0; i < targets.length; ++i) cells[targets[i]] = !cells[targets[i]];
}

function create(random) {
    var cells = new Array(25).fill(false);
    var rng = random || Math.random;
    // Scramble a solved board with legal moves, so every puzzle has a solution.
    for (var i = 0; i < 25; ++i) if (rng() < 0.5) toggle(cells, i);
    if (cells.indexOf(true) === -1) toggle(cells, 12);
    return { cells: cells, moves: 0, status: "playing" };
}

function press(state, index) {
    if (state.status !== "playing" || index < 0 || index >= 25) return;
    toggle(state.cells, index);
    ++state.moves;
    if (state.cells.indexOf(true) === -1) state.status = "won";
}
