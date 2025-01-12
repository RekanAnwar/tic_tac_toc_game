import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';

final gameControllerProvider =
    StateNotifierProvider<GameController, GameModel>((ref) {
  return GameController();
});

class GameController extends StateNotifier<GameModel> {
  GameController() : super(GameModel.initial());

  void makeMove(int row, int col) {
    if (state.board[row][col] != Player.none || state.gameOver) return;

    final newBoard = List<List<Player>>.from(state.board);
    newBoard[row][col] = state.currentPlayer;

    final (winner, winningLine) = _checkWinner(newBoard);
    final gameOver = winner != null || _isBoardFull(newBoard);

    state = state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == Player.X ? Player.O : Player.X,
      gameOver: gameOver,
      winner: winner,
      winningLine: winningLine,
    );
  }

  void resetGame() {
    state = GameModel.initial();
  }

  (Player?, List<List<int>>?) _checkWinner(List<List<Player>> board) {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (board[i][0] != Player.none &&
          board[i][0] == board[i][1] &&
          board[i][1] == board[i][2]) {
        return (
          board[i][0],
          [
            [i, 0],
            [i, 1],
            [i, 2]
          ]
        );
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (board[0][i] != Player.none &&
          board[0][i] == board[1][i] &&
          board[1][i] == board[2][i]) {
        return (
          board[0][i],
          [
            [0, i],
            [1, i],
            [2, i]
          ]
        );
      }
    }

    // Check diagonals
    if (board[0][0] != Player.none &&
        board[0][0] == board[1][1] &&
        board[1][1] == board[2][2]) {
      return (
        board[0][0],
        [
          [0, 0],
          [1, 1],
          [2, 2]
        ]
      );
    }

    if (board[0][2] != Player.none &&
        board[0][2] == board[1][1] &&
        board[1][1] == board[2][0]) {
      return (
        board[0][2],
        [
          [0, 2],
          [1, 1],
          [2, 0]
        ]
      );
    }

    return (null, null);
  }

  bool _isBoardFull(List<List<Player>> board) {
    return board.every((row) => row.every((cell) => cell != Player.none));
  }
}
