import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/models/online_player_model.dart';

final gameControllerProvider =
    StateNotifierProvider<GameController, AsyncValue<GameModel>>((ref) {
  return GameController(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

// Provider to listen for rematch decline
final rematchDeclinedProvider = StreamProvider<bool>((ref) {
  final gameState = ref.watch(gameControllerProvider);
  final gameId = gameState.value?.gameId;

  if (gameId == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('games')
      .doc(gameId)
      .snapshots()
      .map((snapshot) => snapshot.data()?['rematchDeclined'] == true);
});

class GameController extends StateNotifier<AsyncValue<GameModel>> {
  GameController(this._firestore, this._auth)
      : super(AsyncValue.data(GameModel.initial()));

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription? _gameSubscription;

  void startLocalGame() {
    state = AsyncValue.data(GameModel.initial());
  }

  Future<void> startOnlineGame(
      String gameId, String player1Id, String player2Id) async {
    try {
      final game = GameModel.initial().copyWith(
        gameId: gameId,
        player1Id: player1Id,
        player2Id: player2Id,
        lastMoveTimestamp: DateTime.now(),
      );

      await _firestore.collection('games').doc(gameId).set(game.toMap());

      _listenToGame(gameId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _listenToGame(String gameId) {
    _gameSubscription?.cancel();
    _gameSubscription =
        _firestore.collection('games').doc(gameId).snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          state = AsyncValue.data(GameModel.fromMap({
            ...snapshot.data()!,
            'gameId': snapshot.id,
          }));
        }
      },
      onError: (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  Future<void> makeMove(int row, int col) async {
    final currentState = state.value;
    if (currentState == null) return;

    // For local game
    if (currentState.gameId == null) {
      _makeLocalMove(row, col);
      return;
    }

    // For online game
    if (!_canMakeMove(currentState)) return;

    // Don't allow move if cell is already taken
    if (currentState.board[row][col] != Player.none) return;

    try {
      final newBoard = List<List<Player>>.from(currentState.board);
      newBoard[row][col] = currentState.currentPlayer;

      final (winner, winningLine) = _checkWinner(newBoard);
      final gameOver = winner != null || _isBoardFull(newBoard);

      final updatedGame = currentState.copyWith(
        board: newBoard,
        currentPlayer:
            currentState.currentPlayer == Player.X ? Player.O : Player.X,
        gameOver: gameOver,
        winner: winner,
        winningLine: winningLine,
        lastMoveTimestamp: DateTime.now(),
      );

      // Convert 2D board to flat array for Firestore
      final flatBoard = [
        for (var row in newBoard)
          for (var cell in row) cell.toString()
      ];

      final updateData = {
        'board': flatBoard,
        'currentPlayer': updatedGame.currentPlayer.toString(),
        'gameOver': gameOver,
        'lastMoveTimestamp':
            updatedGame.lastMoveTimestamp?.millisecondsSinceEpoch,
      };

      if (winner != null) {
        updateData['winner'] = winner.toString();
        if (winningLine != null) {
          updateData['winningLine'] =
              winningLine.expand((cell) => [cell[0], cell[1]]).toList();
        }
      } else if (gameOver) {
        // It's a draw
        updateData['winner'] = null;
        updateData['winningLine'] = null;
      }

      await _firestore
          .collection('games')
          .doc(currentState.gameId)
          .update(updateData);

      // Update players' status when game is over
      if (gameOver &&
          currentState.player1Id != null &&
          currentState.player2Id != null) {
        final batch = _firestore.batch()
          ..update(
              _firestore
                  .collection('onlinePlayers')
                  .doc(currentState.player1Id),
              {
                'status': OnlineStatus.online.toString(),
              })
          ..update(
              _firestore
                  .collection('onlinePlayers')
                  .doc(currentState.player2Id),
              {
                'status': OnlineStatus.online.toString(),
              });

        await batch.commit();
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _makeLocalMove(int row, int col) {
    final currentState = state.value;
    if (currentState == null) return;

    if (currentState.board[row][col] != Player.none || currentState.gameOver) {
      return;
    }

    final newBoard = List<List<Player>>.from(currentState.board);
    newBoard[row][col] = currentState.currentPlayer;

    final (winner, winningLine) = _checkWinner(newBoard);
    final gameOver = winner != null || _isBoardFull(newBoard);

    state = AsyncValue.data(currentState.copyWith(
      board: newBoard,
      currentPlayer:
          currentState.currentPlayer == Player.X ? Player.O : Player.X,
      gameOver: gameOver,
      winner: winner,
      winningLine: winningLine,
      lastMoveTimestamp: DateTime.now(),
    ));
  }

  bool _canMakeMove(GameModel game) {
    // Don't allow moves if game is over
    if (game.gameOver) return false;

    // Don't allow moves if the cell is already taken
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    final isPlayer1 = game.player1Id == currentUserId;
    final isPlayer2 = game.player2Id == currentUserId;

    if (!isPlayer1 && !isPlayer2) return false;

    return (isPlayer1 && game.currentPlayer == Player.X) ||
        (isPlayer2 && game.currentPlayer == Player.O);
  }

  void resetGame() {
    final currentState = state.value;
    if (currentState?.gameId != null) {
      _firestore
          .collection('games')
          .doc(currentState!.gameId)
          .update(GameModel.initial().toMap());
    } else {
      state = AsyncValue.data(GameModel.initial());
    }
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
    for (var row in board) {
      for (var cell in row) {
        if (cell == Player.none) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> requestRematch(String gameId) async {
    try {
      await _firestore.collection('games').doc(gameId).update({
        'rematchRequestedBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> respondToRematch(String gameId, bool accept) async {
    try {
      if (accept) {
        // Reset the game
        final currentState = state.value;
        if (currentState == null) return;

        final newGame = GameModel.initial().copyWith(
          gameId: gameId,
          player1Id: currentState.player1Id,
          player2Id: currentState.player2Id,
          lastMoveTimestamp: DateTime.now(),
        );

        await _firestore.collection('games').doc(gameId).update({
          ...newGame.toMap(),
          'rematchRequestedBy': null, // Clear the rematch request
          'rematchDeclined': false, // Reset rematch declined status
          'playerLeft': null, // Reset player left status
        });

        // Update state directly to trigger UI update
        state = AsyncValue.data(newGame);
      } else {
        // Update players' status and mark rematch as declined
        final currentState = state.value;
        if (currentState?.player1Id != null &&
            currentState?.player2Id != null) {
          final batch = _firestore.batch()
            ..update(_firestore.collection('games').doc(gameId), {
              'rematchRequestedBy': null,
              'rematchDeclined': true,
            })
            ..update(
                _firestore
                    .collection('onlinePlayers')
                    .doc(currentState!.player1Id),
                {
                  'status': OnlineStatus.online.toString(),
                })
            ..update(
                _firestore
                    .collection('onlinePlayers')
                    .doc(currentState.player2Id),
                {
                  'status': OnlineStatus.online.toString(),
                });

          await batch.commit();
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> leaveGame(String gameId, String playerId) async {
    try {
      final gameDoc = await _firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) return;

      final game = GameModel.fromMap({...gameDoc.data()!, 'gameId': gameId});

      // Determine the winner (the player who didn't leave)
      final winner = playerId == game.player1Id ? Player.O : Player.X;

      // Update game document to mark player as left and set game as over
      final batch = _firestore.batch()
        ..update(_firestore.collection('games').doc(gameId), {
          'playerLeft': playerId,
          'gameOver': true,
          'winner': winner.toString(),
        });

      // Update both players' status to online
      if (game.player1Id != null) {
        batch.update(
            _firestore.collection('onlinePlayers').doc(game.player1Id), {
          'status': OnlineStatus.online.toString(),
        });
      }
      if (game.player2Id != null) {
        batch.update(
            _firestore.collection('onlinePlayers').doc(game.player2Id), {
          'status': OnlineStatus.online.toString(),
        });
      }

      await batch.commit();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }
}
