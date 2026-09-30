function result(board) {
    var lines = [[0,1,2], [3,4,5], [6,7,8], [0,3,6], [1,4,7], [2,5,8], [0,4,8], [2,4,6]];
    for (var i = 0; i < lines.length; ++i) {
        var line = lines[i];
        if (board[line[0]] && board[line[0]] === board[line[1]] && board[line[1]] === board[line[2]])
            return board[line[0]];
    }
    return board.indexOf("") === -1 ? "draw" : "playing";
}

function create() {
    return { board: ["", "", "", "", "", "", "", "", ""], status: "playing" };
}

function minimax(board, player, depth, alpha, beta) {
    var outcome = result(board);
    if (outcome === "O") return 10 - depth;
    if (outcome === "X") return depth - 10;
    if (outcome === "draw") return 0;
    var best = player === "O" ? -Infinity : Infinity;
    var order = [4, 0, 2, 6, 8, 1, 3, 5, 7];
    for (var n = 0; n < order.length; ++n) {
        var i = order[n];
        if (board[i]) continue;
        board[i] = player;
        var score = minimax(board, player === "O" ? "X" : "O", depth + 1, alpha, beta);
        board[i] = "";
        best = player === "O" ? Math.max(best, score) : Math.min(best, score);
        if (player === "O") alpha = Math.max(alpha, best);
        else beta = Math.min(beta, best);
        if (beta <= alpha) break;
    }
    return best;
}

function move(state, index) {
    if (state.status !== "playing" || index < 0 || index >= 9 || state.board[index]) return;
    state.board[index] = "X";
    state.status = result(state.board);
    if (state.status !== "playing") return;
    var order = [4, 0, 2, 6, 8, 1, 3, 5, 7], best = -Infinity, chosen = -1;
    for (var i = 0; i < order.length; ++i) {
        var candidate = order[i];
        if (state.board[candidate]) continue;
        state.board[candidate] = "O";
        var score = minimax(state.board, "X", 0, -Infinity, Infinity);
        state.board[candidate] = "";
        if (score > best) { best = score; chosen = candidate; }
    }
    state.board[chosen] = "O";
    state.status = result(state.board);
}
