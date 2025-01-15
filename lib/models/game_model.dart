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
    final flatBoard = (map['board'] as List)
        .map((cell) => Player.values.firstWhere(
              (p) => p.toString() == cell,
              orElse: () => Player.none,
            ))
        .toList();

    final board =
        List.generate(3, (i) => List.generate(3, (j) => flatBoard[i * 3 + j]));

    // Convert flat winning line back to 2D array if it exists
    final flatWinningLine = map['winningLine'] as List?;
    final winningLine = flatWinningLine != null
        ? List.generate(
            flatWinningLine.length ~/ 2,
            (i) => [
              flatWinningLine[i * 2] as int,
              flatWinningLine[i * 2 + 1] as int,
            ],
          )
        : null;

    return GameModel(
      board: board,
      currentPlayer: Player.values.firstWhere(
        (p) => p.toString() == map['currentPlayer'],
        orElse: () => Player.X,
      ),
      gameOver: map['gameOver'] ?? false,
      winner: map['winner'] != null
          ? Player.values.firstWhere(
              (p) => p.toString() == map['winner'],
              orElse: () => Player.none,
            )
          : null,
      winningLine: winningLine,
      gameId: map['gameId'],
      player1Id: map['player1Id'],
      player2Id: map['player2Id'],
      lastMoveTimestamp: map['lastMoveTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMoveTimestamp'])
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
    // Convert 2D board array to flat array
    final flatBoard = [
      for (var row in board)
        for (var cell in row) cell.toString()
    ];

    // Convert winning line to flat array if it exists
    final flatWinningLine =
        winningLine?.expand((cell) => [cell[0], cell[1]]).toList();

    return {
      'board': flatBoard,
      'currentPlayer': currentPlayer.toString(),
      'gameOver': gameOver,
      'winner': winner?.toString(),
      'winningLine': flatWinningLine,
      'gameId': gameId,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'lastMoveTimestamp': lastMoveTimestamp?.millisecondsSinceEpoch,
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
