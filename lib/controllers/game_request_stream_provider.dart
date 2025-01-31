import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/models/game_request.dart';

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
