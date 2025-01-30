import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel extends Equatable {
  const UserModel({
    this.id,
    this.email,
    this.displayName,
    this.wins = 0,
    this.totalGames = 0,
  });

  factory UserModel.fromFirebase(UserCredential credential) => UserModel(
        id: credential.user?.uid,
        email: credential.user?.email,
        displayName: credential.user?.displayName,
      );

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        email: map['email'],
        displayName: map['displayName'],
        wins: map['wins'] ?? 0,
        totalGames: map['totalGames'] ?? 0,
      );

  final String? id;
  final String? email;
  final String? displayName;
  final int wins;
  final int totalGames;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'wins': wins,
        'totalGames': totalGames,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    int? wins,
    int? totalGames,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        wins: wins ?? this.wins,
        totalGames: totalGames ?? this.totalGames,
      );

  @override
  List<Object?> get props => [id, email, displayName, wins, totalGames];
}
