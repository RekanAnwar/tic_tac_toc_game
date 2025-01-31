import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_async_notifier.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/models/game_request.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

final onlineGameAsyncNotifierProvider =
    AsyncNotifierProvider<OnlineGameAsyncNotifier, List<UserModel>>(
  () => OnlineGameAsyncNotifier(FirebaseFirestore.instance),
);

class OnlineGameAsyncNotifier extends AsyncNotifier<List<UserModel>> {
  OnlineGameAsyncNotifier(this._firestore);

  @override
  Future<List<UserModel>> build() async {
    final isLoggedIn = ref.watch(authAsyncNotifierProvider.select(
      (auth) => auth.value != null,
    ));

    if (!isLoggedIn) return [];

    _initializeOnlineStatus();
    _listenToOnlinePlayers();

    ref.onDispose(() {
      _onlinePlayersSubscription?.cancel();
      _onlineStatusTimer?.cancel();
    });

    return [];
  }

  final FirebaseFirestore _firestore;
  StreamSubscription? _onlinePlayersSubscription;
  Timer? _onlineStatusTimer;

  void _initializeOnlineStatus() {
    // Update online status periodically
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateOnlineStatus();
    });

    // Update status when app starts
    _updateOnlineStatus();

    // Set status to offline when user signs out
    ref.listen(authAsyncNotifierProvider, (previous, next) {
      if (next.value == null) {
        _setOfflineStatus();
      }
    });
  }

  void _listenToOnlinePlayers() {
    final user = ref.watch(authAsyncNotifierProvider).value!;

    _onlinePlayersSubscription?.cancel();
    _onlinePlayersSubscription = _firestore
        .collection('users')
        .where('id', isNotEqualTo: user.id)
        .snapshots()
        .listen(
      (snapshot) {
        final players =
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();

        state = AsyncValue.data(players);
      },
      onError: (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  Future<void> _updateOnlineStatus() async {
    final user = ref.read(authAsyncNotifierProvider).value!;

    try {
      await _firestore.collection('users').doc(user.id).update({
        'status': OnlineStatus.online.toString(),
      });
    } catch (e) {
      log('Error setting online status: $e');
      // Handle error
    }
  }

  Future<void> _setOfflineStatus() async {
    final user = ref.read(authAsyncNotifierProvider).value!;

    try {
      await _firestore.collection('users').doc(user.id).update({
        'status': OnlineStatus.offline.toString(),
      });
    } catch (e) {
      log('Error setting offline status: $e');
      // Handle error
    }
  }

  Future<bool> hasActiveRequests() async {
    final user = ref.read(authAsyncNotifierProvider).value!;

    try {
      // Check for pending requests sent by the user
      final sentRequests = await _firestore
          .collection('gameRequests')
          .where('fromPlayerId', isEqualTo: user.id)
          .where('status', isEqualTo: GameRequestStatus.pending.toString())
          .get();

      // Check for pending requests received by the user
      final receivedRequests = await _firestore
          .collection('gameRequests')
          .where('toPlayerId', isEqualTo: user.id)
          .where('status', isEqualTo: GameRequestStatus.pending.toString())
          .get();

      return sentRequests.docs.isNotEmpty || receivedRequests.docs.isNotEmpty;
    } catch (e) {
      log('Error checking active requests: $e');
      return false;
    }
  }

  Future<void> cleanupGameRequests() async {
    final user = ref.watch(authAsyncNotifierProvider).value!;

    try {
      // Get all pending requests involving the current user
      final sentRequests = await _firestore
          .collection('gameRequests')
          .where('fromPlayerId', isEqualTo: user.id)
          .where('status', isEqualTo: GameRequestStatus.pending.toString())
          .get();

      final receivedRequests = await _firestore
          .collection('gameRequests')
          .where('toPlayerId', isEqualTo: user.id)
          .where('status', isEqualTo: GameRequestStatus.pending.toString())
          .get();

      // Create a batch to update all requests
      final batch = _firestore.batch();

      // Update all requests to rejected status
      for (var doc in [...sentRequests.docs, ...receivedRequests.docs]) {
        batch.update(doc.reference, {
          'status': GameRequestStatus.rejected.toString(),
        });
      }

      await batch.commit();
    } catch (e) {
      log('Error cleaning up game requests: $e');
    }
  }

  Future<void> sendGameRequest(String toPlayerId) async {
    final user = ref.watch(authAsyncNotifierProvider).value!;

    try {
      // Check if either player has any active requests
      final hasActive = await hasActiveRequests();
      if (hasActive) {
        throw Exception(
            'Cannot send request while having active game requests');
      }

      // Check if target player has active requests
      final targetRequests = await _firestore
          .collection('gameRequests')
          .where(Filter.or(
            Filter('fromPlayerId', isEqualTo: toPlayerId),
            Filter('toPlayerId', isEqualTo: toPlayerId),
          ))
          .where('status', isEqualTo: GameRequestStatus.pending.toString())
          .get();

      if (targetRequests.docs.isNotEmpty) {
        throw Exception('Player is currently busy with another request');
      }

      await _firestore.collection('gameRequests').add({
        'fromPlayerId': user.id,
        'toPlayerId': toPlayerId,
        'status': GameRequestStatus.pending.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> respondToGameRequest(String requestId, bool accept) async {
    try {
      final batch = _firestore.batch();
      final requestDoc =
          await _firestore.collection('gameRequests').doc(requestId).get();

      if (!requestDoc.exists) return;

      final request = GameRequest.fromMap({
        ...requestDoc.data()!,
        'id': requestDoc.id,
      });

      if (accept) {
        // Create a new game document with a flattened board representation
        final gameDoc = await _firestore.collection('games').add({
          'player1Id': request.fromPlayerId,
          'player2Id': request.toPlayerId,
          'board': [
            Player.none.index,
            Player.none.index,
            Player.none.index,
            Player.none.index,
            Player.none.index,
            Player.none.index,
            Player.none.index,
            Player.none.index,
            Player.none.index,
          ],
          'currentPlayer': Player.X.index,
          'gameOver': false,
          'lastMoveTimestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Update request status and game ID
        batch
          ..update(_firestore.collection('gameRequests').doc(requestId), {
            'status': GameRequestStatus.accepted.toString(),
            'gameId': gameDoc.id,
            'isGameActive': true,
          })
          ..update(
              // Update both players' status to inGame
              _firestore.collection('users').doc(request.fromPlayerId),
              {'status': OnlineStatus.inGame.toString()})
          ..update(_firestore.collection('users').doc(request.toPlayerId), {
            'status': OnlineStatus.inGame.toString(),
          });

        // Commit all updates atomically
        await batch.commit();
      } else {
        await _firestore.collection('gameRequests').doc(requestId).update({
          'status': GameRequestStatus.rejected.toString(),
          'isGameActive': false,
        });
      }
    } catch (e) {
      log('Error responding to game request: $e');
      // Handle error
    }
  }
}
