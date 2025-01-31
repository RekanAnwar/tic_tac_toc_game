import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserModel extends Equatable {
  const UserModel({
    this.id,
    this.email,
    this.displayName,
    this.wins = 0,
    this.totalGames = 0,
    this.status = OnlineStatus.offline,
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
        status: OnlineStatus.values.firstWhere(
          (e) => e.toString() == map['status'],
          orElse: () => OnlineStatus.offline,
        ),
      );

  final String? id;
  final String? email;
  final String? displayName;
  final int wins;
  final int totalGames;
  final OnlineStatus status;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'wins': wins,
        'totalGames': totalGames,
        'status': status.toString(),
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    int? wins,
    int? totalGames,
    OnlineStatus? status,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        wins: wins ?? this.wins,
        totalGames: totalGames ?? this.totalGames,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [id, email, displayName, wins, totalGames, status];
}

enum OnlineStatus {
  online,
  inGame,
  offline;

  Color get color => switch (this) {
        OnlineStatus.online => Colors.green,
        OnlineStatus.inGame => Colors.orange,
        OnlineStatus.offline => Colors.grey,
      };

  String get text => switch (this) {
        OnlineStatus.online => 'Online',
        OnlineStatus.inGame => 'In Game',
        OnlineStatus.offline => 'Offline',
      };
}
