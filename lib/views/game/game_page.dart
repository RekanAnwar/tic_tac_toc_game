import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/game_controller.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';

class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(gameControllerProvider.notifier).resetGame(),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            gameState.gameOver
                ? gameState.winner != null
                    ? 'Winner: ${gameState.winner.toString().split('.').last}'
                    : 'Draw!'
                : 'Current Player: ${gameState.currentPlayer.toString().split('.').last}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (row) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (col) => GestureDetector(
                        onTap: () => ref
                            .read(gameControllerProvider.notifier)
                            .makeMove(row, col),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Center(
                            child: Text(
                              _getPlayerSymbol(gameState.board[row][col]),
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlayerSymbol(Player player) {
    switch (player) {
      case Player.X:
        return 'X';
      case Player.O:
        return 'O';
      case Player.none:
        return '';
    }
  }
}
