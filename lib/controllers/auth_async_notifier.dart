import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

final authAsyncNotifierProvider =
    AsyncNotifierProvider<AuthAsyncNotifier, UserModel?>(
  () => AuthAsyncNotifier(FirebaseAuth.instance),
  name: 'authControllerProvider',
);

class AuthAsyncNotifier extends AsyncNotifier<UserModel?> {
  AuthAsyncNotifier(this._auth);

  @override
  Future<UserModel?> build() async {
    state = const AsyncValue.loading();

    await getUser();

    return state.value;
  }

  final FirebaseAuth _auth;

  Future<void> getUser() async {

    final user = _auth.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      state = AsyncValue.data(
        UserModel.fromMap(userDoc.data() as Map<String, dynamic>),
      );
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signUp(
    String username,
    String email,
    String password,
  ) async {
    try {
      state = const AsyncValue.loading();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'id': credential.user!.uid,
        'email': credential.user!.email,
        'displayName': username,
        'status': OnlineStatus.online.toString(),
        'wins': 0,
        'totalGames': 0,
      });

      await getUser();
    } catch (e, st) {
      log(e.toString(), error: e, stackTrace: st);
      state = const AsyncValue.data(null);
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set(
        {'status': OnlineStatus.online.toString()},
        SetOptions(merge: true),
      );

      await getUser();
    } catch (e, st) {
      log(e.toString(), error: e, stackTrace: st);
      state = const AsyncValue.data(null);

      rethrow;
    }
  }

  Future<void> signOut() async {
    final user = state.value!;

    await FirebaseFirestore.instance.collection('users').doc(user.id).set(
      {'status': OnlineStatus.offline.toString()},
      SetOptions(merge: true),
    );

    await _auth.signOut();

    state = const AsyncValue.data(null);
  }

  Future<void> updateGameStats(String userId, bool isWinner) async {
    try {
      log('Updating game stats for user: $userId');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final currentStats = userDoc.data() ?? {};

      final user = UserModel.fromMap(currentStats);

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        ...currentStats,
        'totalGames': user.totalGames + 1,
        'wins': user.wins + (isWinner ? 1 : 0),
      }, SetOptions(merge: true));

      // Refresh user data if it's the current user
      if (userId == _auth.currentUser?.uid) {
        await getUser();
      }
    } catch (e, st) {
      log('Error updating game stats', error: e, stackTrace: st);
      rethrow;
    }
  }
}
