function food(state, random) {
    var empty = [];
    for (var i = 0; i < 400; ++i)
        if (state.body.indexOf(i) === -1) empty.push(i);
    return empty.length ? empty[Math.floor(random() * empty.length)] : -1;
}

function create(random) {
    var state = { body: [210, 209, 208], direction: 1, pending: -1,
                  score: 0, status: "playing", food: -1 };
    state.food = food(state, random || Math.random);
    return state;
}

// Clockwise: up, right, down, left. One accepted turn per movement.
function turn(state, direction) {
    if (state.status !== "playing" || state.pending !== -1
            || direction === state.direction || direction === (state.direction + 2) % 4)
        return;
    state.pending = direction;
}

function tick(state, random) {
    if (state.status !== "playing") return;
    if (state.pending !== -1) state.direction = state.pending;
    state.pending = -1;
    var head = state.body[0];
    var x = (head % 20 + [0, 1, 0, -1][state.direction] + 20) % 20;
    var y = (Math.floor(head / 20) + [-1, 0, 1, 0][state.direction] + 20) % 20;
    var next = y * 20 + x;
    var grows = next === state.food;
    var collision = state.body.indexOf(next);
    if (collision !== -1 && (grows || collision !== state.body.length - 1)) {
        state.status = "lost";
        return;
    }
    if (!grows) state.body.pop();
    state.body.unshift(next);
    if (grows) {
        ++state.score;
        state.food = food(state, random || Math.random);
        if (state.food === -1) state.status = "won";
    }
}
