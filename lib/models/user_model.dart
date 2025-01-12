import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel extends Equatable {
  const UserModel({
    this.id,
    this.email,
  });

  factory UserModel.fromFirebase(UserCredential credential) => UserModel(
        id: credential.user?.uid,
        email: credential.user?.email,
      );

  final String? id;
  final String? email;

  @override
  List<Object?> get props => [id, email];
}
