import 'package:equatable/equatable.dart';

enum Player { X, O, none }

class GameModel extends Equatable {
  const GameModel({
    required this.board,
    required this.currentPlayer,
    this.gameOver = false,
    this.winner,
    this.winningLine,
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
  final List<List<Player>> board;
  final Player currentPlayer;
  final bool gameOver;
  final Player? winner;
  final List<List<int>>? winningLine;

  GameModel copyWith({
    List<List<Player>>? board,
    Player? currentPlayer,
    bool? gameOver,
    Player? winner,
    List<List<int>>? winningLine,
  }) {
    return GameModel(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      gameOver: gameOver ?? this.gameOver,
      winner: winner ?? this.winner,
      winningLine: winningLine ?? this.winningLine,
    );
  }

  @override
  List<Object?> get props =>
      [board, currentPlayer, gameOver, winner, winningLine];
}
