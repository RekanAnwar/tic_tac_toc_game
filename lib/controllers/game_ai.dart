import 'dart:math';

import 'package:riverpod/riverpod.dart';

final difficultyProvider = StateProvider<int>((ref) => 3);

class TicTacToe {
  TicTacToe()
      : board = List.generate(boardSize, (_) => List.filled(boardSize, ''),
            growable: false);
  static const int boardSize = 3;
  List<List<String>> board;

  bool makeMove(int row, int col, String player) {
    if (board[row][col] == '') {
      board[row][col] = player;
      return true;
    }
    return false;
  }

  String checkWinner() {
    for (int i = 0; i < boardSize; i++) {
      // Check rows and columns
      if (board[i][0] != '' &&
          board[i][0] == board[i][1] &&
          board[i][1] == board[i][2]) return board[i][0];
      if (board[0][i] != '' &&
          board[0][i] == board[1][i] &&
          board[1][i] == board[2][i]) return board[0][i];
    }
    // Check diagonals
    if (board[0][0] != '' &&
        board[0][0] == board[1][1] &&
        board[1][1] == board[2][2]) return board[0][0];
    if (board[0][2] != '' &&
        board[0][2] == board[1][1] &&
        board[1][1] == board[2][0]) return board[0][2];
    // Check for tie
    if (board.every((row) => row.every((cell) => cell != ''))) return 'Tie';
    return '';
  }

  List<int> bestMove(String player, int difficulty) {
    int bestScore = -1000;
    List<int> move = [-1, -1];

    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == '') {
          board[i][j] = player;
          final int score = minimax(0, false, difficulty);
          board[i][j] = '';
          if (score > bestScore) {
            bestScore = score;
            move = [i, j];
          }
        }
      }
    }
    return move;
  }

  int minimax(int depth, bool isMaximizing, int difficulty) {
    final String result = checkWinner();
    if (result != '') {
      if (result == 'O') return difficulty - depth;
      if (result == 'X') return depth - difficulty;
      return 0;
    }

    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < boardSize; i++) {
        for (int j = 0; j < boardSize; j++) {
          if (board[i][j] == '') {
            board[i][j] = 'O';
            final int score = minimax(depth + 1, false, difficulty);
            board[i][j] = '';
            bestScore = max(score, bestScore);
          }
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < boardSize; i++) {
        for (int j = 0; j < boardSize; j++) {
          if (board[i][j] == '') {
            board[i][j] = 'X';
            final int score = minimax(depth + 1, true, difficulty);
            board[i][j] = '';
            bestScore = min(score, bestScore);
          }
        }
      }
      return bestScore;
    }
  }
}
