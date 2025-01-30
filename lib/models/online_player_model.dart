import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

class OnlinePlayerModel extends Equatable {
  factory OnlinePlayerModel.fromMap(Map<String, dynamic> map) {
    return OnlinePlayerModel(
      id: map['id'] as String,
      email: map['email'] as String,
      status: OnlineStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => OnlineStatus.offline,
      ),
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,
    );
  }
  const OnlinePlayerModel({
    required this.id,
    required this.email,
    this.status = OnlineStatus.offline,
    this.lastSeen,
  });

  final String id;
  final String email;
  final OnlineStatus status;
  final DateTime? lastSeen;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'status': status.toString(),
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
    };
  }

  OnlinePlayerModel copyWith({
    String? id,
    String? email,
    OnlineStatus? status,
    DateTime? lastSeen,
  }) {
    return OnlinePlayerModel(
      id: id ?? this.id,
      email: email ?? this.email,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [id, email, status, lastSeen];
}

class GameRequest extends Equatable {
  factory GameRequest.fromMap(Map<String, dynamic> map) {
    return GameRequest(
      id: map['id'] as String,
      fromPlayerId: map['fromPlayerId'] as String,
      toPlayerId: map['toPlayerId'] as String,
      status: GameRequestStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => GameRequestStatus.pending,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      gameId: map['gameId'] as String?,
    );
  }
  const GameRequest({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.status,
    required this.timestamp,
    this.gameId,
  });

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final GameRequestStatus status;
  final DateTime timestamp;
  final String? gameId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromPlayerId': fromPlayerId,
      'toPlayerId': toPlayerId,
      'status': status.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'gameId': gameId,
    };
  }

  GameRequest copyWith({
    String? id,
    String? fromPlayerId,
    String? toPlayerId,
    GameRequestStatus? status,
    DateTime? timestamp,
    String? gameId,
  }) {
    return GameRequest(
      id: id ?? this.id,
      fromPlayerId: fromPlayerId ?? this.fromPlayerId,
      toPlayerId: toPlayerId ?? this.toPlayerId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      gameId: gameId ?? this.gameId,
    );
  }

  @override
  List<Object?> get props =>
      [id, fromPlayerId, toPlayerId, status, timestamp, gameId];
}

enum GameRequestStatus { pending, accepted, rejected, cancelled }
