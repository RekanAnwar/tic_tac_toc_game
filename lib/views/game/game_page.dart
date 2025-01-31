import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_state_notifier.dart';
import 'package:tic_tac_toc_game/controllers/game_state_notifier.dart';
import 'package:tic_tac_toc_game/controllers/online_game_state_notifier.dart';
import 'package:tic_tac_toc_game/extensions/context_extension.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/models/online_player_model.dart';
import 'package:tic_tac_toc_game/views/game/widgets/game_cell.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({
    super.key,
    required this.game,
  });

  final GameModel game;

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
    // Clean up any pending requests when entering a game
    if (widget.game.gameId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onlineGameControllerProvider.notifier).cleanupGameRequests();
      });
    }
  }

  Future<void> _initializeGame() async {
    if (widget.game.gameId != null &&
        widget.game.player1Id != null &&
        widget.game.player2Id != null) {
      await ref.read(gameControllerProvider.notifier).startOnlineGame(
            widget.game.gameId!,
            widget.game.player1Id!,
            widget.game.player2Id!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    final gameState = ref.watch(gameControllerProvider);
    final currentUser = ref.watch(authControllerProvider).value!;

    ref.listen(
      gameControllerProvider,
      (previous, next) {
        if (next.value != null && next.value!.gameOver) {
          final game = next.value!;
          final isWinner = game.winner != null &&
              ((game.winner == Player.X && game.player1Id == currentUser.id) ||
                  (game.winner == Player.O &&
                      game.player2Id == currentUser.id));

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(
                game.winner != null
                    ? isWinner
                        ? 'You Won! 🎉'
                        : 'You Lost! 😔'
                    : 'Draw Game! 🤝',
                style: TextStyle(
                  color: game.winner != null
                      ? isWinner
                          ? Colors.green
                          : Colors.red
                      : null,
                ),
              ),
              content: Text(
                game.winner != null
                    ? isWinner
                        ? 'Congratulations! You have won the game!'
                        : 'Better luck next time! Keep playing to improve.'
                    : 'It\'s a draw! Great game by both players!',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('onlinePlayers')
                        .doc(currentUser.id)
                        .update({
                      'id': currentUser.id,
                      'email': currentUser.email,
                      'status': OnlineStatus.online.toString(),
                      'lastSeen': DateTime.now().millisecondsSinceEpoch,
                    });


                    if (!context.mounted) return;

                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          );
        }
      },
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 0,
          centerTitle: true,
          leading: const SizedBox.shrink(),
          title: const Text('Tic Tac Toe'),
          actions: [
            if (game.gameId != null) // Add exit button for online games
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () async {
                  await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Leave Game?'),
                      content: const Text(
                          'Are you sure you want to leave the game? The other player will win.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(gameControllerProvider.notifier)
                                .leaveGame(game.gameId!, currentUser.id!);
                            if (context.mounted) {
                              Navigator.pop(context, true);
                              Navigator.of(context).pushReplacementNamed(
                                '/home',
                              );
                            }
                          },
                          child: const Text('Leave'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        body: gameState.when(
          data: (game) => _buildGameBody(context, game, currentUser.id),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildGameBody(
    BuildContext context,
    GameModel game,
    String? currentUserId,
  ) {
    final isOnlineGame = game.gameId != null;
    final isCurrentPlayerTurn = !isOnlineGame ||
        (game.currentPlayer == Player.X && game.player1Id == currentUserId) ||
        (game.currentPlayer == Player.O && game.player2Id == currentUserId);

    // Show message if other player left
    if (game.playerLeft != null && game.playerLeft != currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('You Won!'),
            content: const Text('The other player left the game. You win!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        );
      });
    }

    return DecoratedBox(
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
          if (isOnlineGame && !isCurrentPlayerTurn && !game.gameOver)
            const Text(
              "Opponent's turn",
              style: TextStyle(fontSize: 24, color: Colors.orange),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              game.gameOver
                  ? game.winner != null
                      ? 'Winner: ${game.winner.toString().split('.').last}'
                      : 'Draw!'
                  : 'Current Player: ${game.currentPlayer.toString().split('.').last}',
              key: ValueKey(game.gameOver),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: game.gameOver
                        ? game.winner != null
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
                        player: game.board[row][col],
                        onTap: isCurrentPlayerTurn && !game.gameOver
                            ? () => ref
                                .read(gameControllerProvider.notifier)
                                .makeMove(row, col)
                            : null,
                        isWinningCell: game.winningLine?.any(
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
    );
  }
}
