
import 'package:equatable/equatable.dart';

class GameRequest extends Equatable {
  const GameRequest({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.status,
    required this.timestamp,
    this.gameId,
    this.isGameActive = false,
  });

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
      isGameActive: map['isGameActive'] as bool? ?? false,
    );
  }

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final GameRequestStatus status;
  final DateTime timestamp;
  final String? gameId;
  final bool isGameActive;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromPlayerId': fromPlayerId,
      'toPlayerId': toPlayerId,
      'status': status.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'gameId': gameId,
      'isGameActive': isGameActive,
    };
  }

  GameRequest copyWith({
    String? id,
    String? fromPlayerId,
    String? toPlayerId,
    GameRequestStatus? status,
    DateTime? timestamp,
    String? gameId,
    bool? isGameActive,
  }) {
    return GameRequest(
      id: id ?? this.id,
      fromPlayerId: fromPlayerId ?? this.fromPlayerId,
      toPlayerId: toPlayerId ?? this.toPlayerId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      gameId: gameId ?? this.gameId,
      isGameActive: isGameActive ?? this.isGameActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fromPlayerId,
        toPlayerId,
        status,
        timestamp,
        gameId,
        isGameActive,
      ];
}

enum GameRequestStatus { pending, accepted, rejected, cancelled }
