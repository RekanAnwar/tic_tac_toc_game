import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>(
  (ref) => AuthController(FirebaseAuth.instance),
  name: 'authControllerProvider',
);

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  AuthController(this._auth) : super(const AsyncValue.data(null)) {
    _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(
        user == null ? null : UserModel(id: user.uid, email: user.email),
      );
    });
  }

  final FirebaseAuth _auth;

  Future<void> signUp(String email, String password) async {
    try {
      state = const AsyncValue.loading();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      state = AsyncValue.data(UserModel.fromFirebase(credential));
    } catch (e, st) {
      log(e.toString(), error: e, stackTrace: st);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      state = AsyncValue.data(UserModel.fromFirebase(credential));
    } catch (e, st) {
      log(e.toString(), error: e, stackTrace: st);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();

    state = const AsyncValue.data(null);
  }
}
