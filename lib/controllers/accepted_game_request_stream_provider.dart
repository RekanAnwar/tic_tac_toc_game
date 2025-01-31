import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_async_notifier.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/models/game_request.dart';

final acceptedGameRequestProvider = StreamProvider<GameModel?>(
  (ref) {
    final isLoggedIn = ref.watch(authAsyncNotifierProvider.select(
      (auth) => auth.value != null,
    ));

    if (!isLoggedIn) return Stream.value(null);

    final user = ref.watch(authAsyncNotifierProvider).value!;
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('gameRequests')
        .where(Filter.or(
          Filter('fromPlayerId', isEqualTo: user.id),
          Filter('toPlayerId', isEqualTo: user.id),
        ))
        .where(Filter.and(
          Filter('status', isEqualTo: GameRequestStatus.accepted.toString()),
          Filter('gameId', isNull: false),
          Filter('isGameActive', isEqualTo: true),
        ))
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final request = GameRequest.fromMap({...doc.data(), 'id': doc.id});
      final gameDoc =
          await firestore.collection('games').doc(request.gameId).get();

      if (!gameDoc.exists) {
        // Update the game request to mark it as inactive
        await doc.reference.update({'isGameActive': false});
        return null;
      }

      return GameModel.fromMap(
        {...gameDoc.data() ?? {}, 'gameId': request.gameId},
      );
    });
  },
);
