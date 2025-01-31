import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_async_notifier.dart';
import 'package:tic_tac_toc_game/models/game_request.dart';

final gameRequestsProvider = StreamProvider<List<GameRequest>>(
  (ref) {
    final isLoggedIn = ref.watch(authAsyncNotifierProvider.select(
      (auth) => auth.value != null,
    ));

    if (!isLoggedIn) return Stream.value([]);

    final user = ref.watch(authAsyncNotifierProvider).value!;
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('gameRequests')
        .where('toPlayerId', isEqualTo: user.id)
        .where('status', isEqualTo: GameRequestStatus.pending.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameRequest.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  },
);
