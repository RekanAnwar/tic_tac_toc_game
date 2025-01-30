import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/models/online_player_model.dart';

final onlineGameControllerProvider = StateNotifierProvider<OnlineGameController,
    AsyncValue<List<OnlinePlayerModel>>>(
  (ref) {
    return OnlineGameController(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
  },
);

final gameRequestsProvider = StreamProvider<List<GameRequest>>(
  (ref) {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    if (auth.currentUser == null) return Stream.value([]);

    return firestore
        .collection('gameRequests')
        .where('toPlayerId', isEqualTo: auth.currentUser!.uid)
        .where('status', isEqualTo: GameRequestStatus.pending.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameRequest.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  },
);

// Provider to listen for accepted game requests
final acceptedGameRequestProvider = StreamProvider<Map<String, String>?>(
  (ref) {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    if (auth.currentUser == null) return Stream.value(null);

    return firestore
        .collection('gameRequests')
        .where(Filter.or(
          Filter('fromPlayerId', isEqualTo: auth.currentUser!.uid),
          Filter('toPlayerId', isEqualTo: auth.currentUser!.uid),
        ))
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final request = GameRequest.fromMap({...doc.data(), 'id': doc.id});

      // Only proceed if the request is accepted and has a game ID
      if (request.status == GameRequestStatus.accepted &&
          request.gameId != null) {
        // Verify that the game exists
        final gameDoc =
            await firestore.collection('games').doc(request.gameId).get();

        if (gameDoc.exists) {
          return {
            'gameId': request.gameId!,
            'player1Id': request.fromPlayerId,
            'player2Id': request.toPlayerId,
          };
        }
      }
      return null;
    });
  },
);

class OnlineGameController
    extends StateNotifier<AsyncValue<List<OnlinePlayerModel>>> {
  OnlineGameController(this._firestore, this._auth)
      : super(const AsyncValue.loading()) {
    _initializeOnlineStatus();
    _listenToOnlinePlayers();
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription? _onlinePlayersSubscription;
  Timer? _onlineStatusTimer;

  void _initializeOnlineStatus() {
    if (_auth.currentUser == null) return;

    // Update online status periodically
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateOnlineStatus();
    });

    // Update status when app starts
    _updateOnlineStatus();

    // Set status to offline when user signs out
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _setOfflineStatus();
      }
    });
  }

  Future<void> _updateOnlineStatus() async {
    if (_auth.currentUser == null) return;

    try {
      await _firestore
          .collection('onlinePlayers')
          .doc(_auth.currentUser!.uid)
          .set({
        'id': _auth.currentUser!.uid,
        'email': _auth.currentUser!.email,
        'status': OnlineStatus.online.toString(),
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      log('Error setting online status: $e');
      // Handle error
    }
  }

  Future<void> _setOfflineStatus() async {
    if (_auth.currentUser == null) return;

    try {
      await _firestore
          .collection('onlinePlayers')
          .doc(_auth.currentUser!.uid)
          .set({
        'id': _auth.currentUser!.uid,
        'email': _auth.currentUser!.email,
        'status': OnlineStatus.offline.toString(),
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      log('Error setting offline status: $e');
      // Handle error
    }
  }

  void _listenToOnlinePlayers() {
    if (_auth.currentUser == null) return;

    _onlinePlayersSubscription?.cancel();
    _onlinePlayersSubscription = _firestore
        .collection('onlinePlayers')
        .where('id', isNotEqualTo: _auth.currentUser!.uid)
        .snapshots()
        .listen(
      (snapshot) {
        final players = snapshot.docs
            .map((doc) => OnlinePlayerModel.fromMap(doc.data()))
            .toList();
        state = AsyncValue.data(players);
      },
      onError: (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  Future<bool> hasActiveRequests() async {
    if (_auth.currentUser == null) return false;

    try {
      // Check for pending requests sent by the user
      final sentRequests = await _firestore
          .collection('gameRequests')
          .where('fromPlayerId', isEqualTo: _auth.currentUser!.uid)
          .where('status', isEqualTo: GameRequestStatus.pending.toString())
          .get();

      // Check for pending requests received by the user
      final receivedRequests = await _firestore
          .collection('gameRequests')
          .where('toPlayerId', isEqualTo: _auth.currentUser!.uid)
          .where('status', isEqualTo: GameRequestStatus.pending.toString())
          .get();

      return sentRequests.docs.isNotEmpty || receivedRequests.docs.isNotEmpty;
    } catch (e) {
      log('Error checking active requests: $e');
      return false;
    }
  }

  Future<void> cleanupGameRequests() async {
    if (_auth.currentUser == null) return;

    try {
      // Get all pending requests involving the current user
      final sentRequests = await _firestore
          .collection('gameRequests')
          .where('fromPlayerId', isEqualTo: _auth.currentUser!.uid)
          .where('status', isEqualTo: GameRequestStatus.pending.toString())
          .get();

      final receivedRequests = await _firestore
          .collection('gameRequests')
          .where('toPlayerId', isEqualTo: _auth.currentUser!.uid)
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
    if (_auth.currentUser == null) return;

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
        'fromPlayerId': _auth.currentUser!.uid,
        'toPlayerId': toPlayerId,
        'status': GameRequestStatus.pending.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      log('Error sending game request: $e');
      rethrow; // Rethrow to handle in UI
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
          'currentPlayer': Player.X.toString(),
          'gameOver': false,
          'lastMoveTimestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Update request status and game ID
        batch
          ..update(_firestore.collection('gameRequests').doc(requestId), {
            'status': GameRequestStatus.accepted.toString(),
            'gameId': gameDoc.id,
          })
          ..update(
              // Update both players' status to inGame
              _firestore.collection('onlinePlayers').doc(request.fromPlayerId),
              {
                'status': OnlineStatus.inGame.toString(),
              })
          ..update(
              _firestore.collection('onlinePlayers').doc(request.toPlayerId), {
            'status': OnlineStatus.inGame.toString(),
          });

        // Commit all updates atomically
        await batch.commit();
      } else {
        await _firestore.collection('gameRequests').doc(requestId).update({
          'status': GameRequestStatus.rejected.toString(),
        });
      }
    } catch (e) {
      log('Error responding to game request: $e');
      // Handle error
    }
  }

  @override
  void dispose() {
    _onlinePlayersSubscription?.cancel();
    _onlineStatusTimer?.cancel();
    super.dispose();
  }
}
