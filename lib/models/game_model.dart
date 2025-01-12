import 'package:equatable/equatable.dart';

enum Player { X, O, none }

class GameModel extends Equatable {
  const GameModel({
    required this.board,
    required this.currentPlayer,
    this.gameOver = false,
    this.winner,
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

  GameModel copyWith({
    List<List<Player>>? board,
    Player? currentPlayer,
    bool? gameOver,
    Player? winner,
  }) {
    return GameModel(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      gameOver: gameOver ?? this.gameOver,
      winner: winner ?? this.winner,
    );
  }

  @override
  List<Object?> get props => [board, currentPlayer, gameOver, winner];
}
