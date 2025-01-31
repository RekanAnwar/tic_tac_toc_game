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
