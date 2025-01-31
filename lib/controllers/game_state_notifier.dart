import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

final gameControllerProvider =
    StateNotifierProvider<GameController, AsyncValue<GameModel>>(
  (ref) => GameController(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  ),
);

class GameController extends StateNotifier<AsyncValue<GameModel>> {
  GameController(this._firestore, this._auth)
      : super(AsyncValue.data(GameModel.initial()));

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription? _gameSubscription;

  Future<void> startOnlineGame(
    String gameId,
    String player1Id,
    String player2Id,
  ) async {
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
          final data = snapshot.data()!;

          if (data['board'] != null) {
            final rawBoard = List<dynamic>.from(data['board']);

            state = AsyncValue.data(
              GameModel.fromMap(
                {
                  ...data,
                  'board': rawBoard,
                  'gameId': snapshot.id,
                },
              ),
            );
          }
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

    // For online game
    if (!_canMakeMove(currentState)) return;

    // Don't allow move if cell is already taken
    if (currentState.board[row][col] != Player.none) return;

    try {
      final newBoard = List<List<Player>>.from(currentState.board);
      newBoard[row][col] = currentState.currentPlayer;

      final (winner, winningLine) = _checkWinner(newBoard);
      final gameOver = winner != null || _isBoardFull(newBoard);

      // Update game state first
      await _firestore.collection('games').doc(currentState.gameId).update({
        'board': _flattenBoard(newBoard),
        'currentPlayer': currentState.currentPlayer == Player.X
            ? Player.O.index
            : Player.X.index,
        'winner': winner?.index,
        'winningLine': winningLine?.map((pos) => pos[0] * 3 + pos[1]).toList(),
        'lastMoveTimestamp': DateTime.now().toIso8601String(),
        'gameOver': gameOver,
      });

      // Then update statistics if game is over
      if (gameOver) {
        final player1Won = winner == Player.X;
        final player2Won = winner == Player.O;

        // Find and update the game request
        final requests = await _firestore
            .collection('gameRequests')
            .where('gameId', isEqualTo: currentState.gameId)
            .limit(1)
            .get();

        if (requests.docs.isNotEmpty) {
          await requests.docs.first.reference.update({'isGameActive': false});
        }

        // Update player 1 stats
        if (currentState.player1Id != null) {
          final doc1 = await _firestore
              .collection('users')
              .doc(currentState.player1Id)
              .get();

          final currentStats1 = doc1.data() ?? {};
          await _firestore.collection('users').doc(currentState.player1Id).set({
            ...currentStats1,
            'totalGames': (currentStats1['totalGames'] ?? 0) + 1,
            'wins': (currentStats1['wins'] ?? 0) + (player1Won ? 1 : 0),
          }, SetOptions(merge: true));
        }

        // Update player 2 stats
        if (currentState.player2Id != null) {
          final doc2 = await _firestore
              .collection('users')
              .doc(currentState.player2Id)
              .get();

          final currentStats2 = doc2.data() ?? {};
          await _firestore.collection('users').doc(currentState.player2Id).set({
            ...currentStats2,
            'totalGames': (currentStats2['totalGames'] ?? 0) + 1,
            'wins': (currentStats2['wins'] ?? 0) + (player2Won ? 1 : 0),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
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

  Future<void> leaveGame(String gameId, String playerId) async {
    try {
      final gameDoc = await _firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) return;

      final game = GameModel.fromMap({...gameDoc.data()!, 'gameId': gameId});

      final batch = _firestore.batch();

      // Find the game request
      final requests = await _firestore
          .collection('gameRequests')
          .where('gameId', isEqualTo: gameId)
          .limit(1)
          .get();

      if (requests.docs.isNotEmpty) {
        batch.update(requests.docs.first.reference, {'isGameActive': false});
      }

      // If game is already over, just update player statuses
      if (game.gameOver) {
        if (game.player1Id != null) {
          batch.update(_firestore.collection('users').doc(game.player1Id),
              {'status': OnlineStatus.online.toString()});
        }
        if (game.player2Id != null) {
          batch.update(_firestore.collection('users').doc(game.player2Id),
              {'status': OnlineStatus.online.toString()});
        }
      } else {
        // If game is not over, mark as forfeit
        final winner = playerId == game.player1Id ? Player.O : Player.X;
        batch.update(_firestore.collection('games').doc(gameId), {
          'playerLeft': playerId,
          'gameOver': true,
          'winner': winner.index,
        });

        // Update player statuses
        if (game.player1Id != null) {
          batch.update(_firestore.collection('users').doc(game.player1Id),
              {'status': OnlineStatus.online.toString()});
        }
        if (game.player2Id != null) {
          batch.update(_firestore.collection('users').doc(game.player2Id),
              {'status': OnlineStatus.online.toString()});
        }
      }

      await batch.commit();

      // Cancel the game subscription
      _gameSubscription?.cancel();
      // Reset the game state to initial
      state = AsyncValue.data(GameModel.initial());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Helper method to flatten the board
  List<int> _flattenBoard(List<List<Player>> board) {
    return board.expand((row) => row.map((cell) => cell.index)).toList();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }
}
