import 'package:equatable/equatable.dart';

enum Player { X, O, none }

class GameModel extends Equatable {
  const GameModel({
    required this.board,
    required this.currentPlayer,
    this.gameOver = false,
    this.winner,
    this.winningLine,
    this.gameId,
    this.player1Id,
    this.player2Id,
    this.lastMoveTimestamp,
    this.rematchRequestedBy,
    this.rematchDeclined = false,
    this.playerLeft,
  });

  factory GameModel.initial() {
    return GameModel(
      board: List.generate(
        3,
        (_) => List.generate(3, (_) => Player.none),
      ),
      currentPlayer: Player.X,
    );
  }

  factory GameModel.fromMap(Map<String, dynamic> map) {
    // Convert flat board array to 2D array
    final List<dynamic> rawBoard =
        map['board'] as List? ?? List.generate(9, (_) => Player.none.index);

    final board = [
      [for (int i = 0; i < 3; i++) Player.values[rawBoard[i] as int]],
      [for (int i = 3; i < 6; i++) Player.values[rawBoard[i] as int]],
      [for (int i = 6; i < 9; i++) Player.values[rawBoard[i] as int]],
    ];

    return GameModel(
      board: board,
      currentPlayer: map['currentPlayer'] != null
          ? Player.values[map['currentPlayer'] as int]
          : Player.X,
      gameOver: map['gameOver'] ?? false,
      winner:
          map['winner'] != null ? Player.values[map['winner'] as int] : null,
      winningLine: (map['winningLine'] as List?)?.map((pos) {
        final row = (pos as int) ~/ 3;
        final col = pos % 3;
        return <int>[row, col];
      }).toList(),
      gameId: map['gameId'],
      player1Id: map['player1Id'],
      player2Id: map['player2Id'],
      lastMoveTimestamp: map['lastMoveTimestamp'] != null
          ? DateTime.tryParse(map['lastMoveTimestamp'])
          : null,
      rematchRequestedBy: map['rematchRequestedBy'],
      rematchDeclined: map['rematchDeclined'] ?? false,
      playerLeft: map['playerLeft'],
    );
  }

  final List<List<Player>> board;
  final Player currentPlayer;
  final bool gameOver;
  final Player? winner;
  final List<List<int>>? winningLine;
  final String? gameId;
  final String? player1Id;
  final String? player2Id;
  final DateTime? lastMoveTimestamp;
  final String? rematchRequestedBy;
  final bool rematchDeclined;
  final String? playerLeft;

  Map<String, dynamic> toMap() {
    // Convert 2D board to flat array of indices
    final flatBoard =
        board.expand((row) => row.map((cell) => cell.index)).toList();

    return {
      'board': flatBoard,
      'currentPlayer': currentPlayer.index,
      'gameOver': gameOver,
      'winner': winner?.index,
      'winningLine': winningLine?.map((pos) => pos[0] * 3 + pos[1]).toList(),
      'gameId': gameId,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'lastMoveTimestamp': lastMoveTimestamp?.toIso8601String(),
      'rematchRequestedBy': rematchRequestedBy,
      'rematchDeclined': rematchDeclined,
      'playerLeft': playerLeft,
    };
  }

  GameModel copyWith({
    List<List<Player>>? board,
    Player? currentPlayer,
    bool? gameOver,
    Player? winner,
    List<List<int>>? winningLine,
    String? gameId,
    String? player1Id,
    String? player2Id,
    DateTime? lastMoveTimestamp,
    String? rematchRequestedBy,
    bool? rematchDeclined,
    String? playerLeft,
  }) {
    return GameModel(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      gameOver: gameOver ?? this.gameOver,
      winner: winner ?? this.winner,
      winningLine: winningLine ?? this.winningLine,
      gameId: gameId ?? this.gameId,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      lastMoveTimestamp: lastMoveTimestamp ?? this.lastMoveTimestamp,
      rematchRequestedBy: rematchRequestedBy ?? this.rematchRequestedBy,
      rematchDeclined: rematchDeclined ?? this.rematchDeclined,
      playerLeft: playerLeft ?? this.playerLeft,
    );
  }

  @override
  List<Object?> get props => [
        board,
        currentPlayer,
        gameOver,
        winner,
        winningLine,
        gameId,
        player1Id,
        player2Id,
        lastMoveTimestamp,
        rematchRequestedBy,
        rematchDeclined,
        playerLeft,
      ];
}
