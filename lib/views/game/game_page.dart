import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/game_controller.dart';
import 'package:tic_tac_toc_game/extensions/context_extension.dart';
import 'package:tic_tac_toc_game/views/game/widgets/game_cell.dart';

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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                gameState.gameOver
                    ? gameState.winner != null
                        ? 'Winner: ${gameState.winner.toString().split('.').last}'
                        : 'Draw!'
                    : 'Current Player: ${gameState.currentPlayer.toString().split('.').last}',
                key: ValueKey(gameState.gameOver),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: gameState.gameOver
                          ? gameState.winner != null
                              ? context.primary
                              : null
                          : null,
                    ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: context.grey100,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (row) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (col) => GameCell(
                          player: gameState.board[row][col],
                          onTap: () => ref
                              .read(gameControllerProvider.notifier)
                              .makeMove(row, col),
                          isWinningCell: gameState.winningLine?.any(
                                  (cell) => cell[0] == row && cell[1] == col) ??
                              false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
