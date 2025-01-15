import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/game_controller.dart';
import 'package:tic_tac_toc_game/controllers/online_game_controller.dart';
import 'package:tic_tac_toc_game/extensions/context_extension.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/views/game/widgets/game_cell.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({
    super.key,
    this.gameId,
    this.player1Id,
    this.player2Id,
  });

  final String? gameId;
  final String? player1Id;
  final String? player2Id;

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  @override
  void initState() {
    super.initState();
    _initializeGame();
    // Clean up any pending requests when entering a game
    if (widget.gameId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onlineGameControllerProvider.notifier).cleanupGameRequests();
      });
    }
  }

  Future<void> _initializeGame() async {
    if (widget.gameId != null &&
        widget.player1Id != null &&
        widget.player2Id != null) {
      await ref.read(gameControllerProvider.notifier).startOnlineGame(
            widget.gameId!,
            widget.player1Id!,
            widget.player2Id!,
          );
    } else {
      ref.read(gameControllerProvider.notifier).startLocalGame();
    }
  }

  Future<void> _exitGame(BuildContext context) async {
    final game = ref.read(gameControllerProvider).value;
    if (game?.gameId == null) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await ref
          .read(gameControllerProvider.notifier)
          .leaveGame(game!.gameId!, currentUserId);
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error leaving game. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Listen for rematch decline
    ref.listen(rematchDeclinedProvider, (previous, next) {
      if (next.value == true) {
        // Show a message when rematch is declined
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rematch was declined'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    // Remove auto-navigation on game over
    // Instead, show appropriate messages and exit button

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        final game = gameState.value;
        if (game?.gameId == null) {
          return true; // Allow back navigation for local games
        }
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Game?'),
            content: const Text(
                'Are you sure you want to leave the game? The other player will be notified.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, true);
                  await _exitGame(context);
                },
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tic Tac Toe'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Leave Game?'),
                  content: const Text(
                      'Are you sure you want to leave the game? The other player will be notified.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context, true);
                        await _exitGame(context);
                      },
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              );
              if ((shouldExit ?? false) && context.mounted) {
                await _exitGame(context);
              }
            },
          ),
          actions: [
            if (gameState.value?.gameOver == true)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  if (widget.gameId != null) {
                    // Online game - request rematch
                    await ref
                        .read(gameControllerProvider.notifier)
                        .requestRematch(widget.gameId!);
                  } else {
                    // Local game - reset immediately
                    ref.read(gameControllerProvider.notifier).resetGame();
                  }
                },
              ),
            if (widget.gameId != null) // Add exit button for online games
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
                                .leaveGame(widget.gameId!, currentUserId!);
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
          data: (game) => _buildGameBody(context, game, currentUserId),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildGameBody(
      BuildContext context, GameModel game, String? currentUserId) {
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

    // Handle rematch request
    if (game.rematchRequestedBy != null &&
        game.rematchRequestedBy != currentUserId &&
        game.gameOver) {
      // Show rematch request dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Rematch Request'),
            content: const Text('Your opponent wants to play again. Accept?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(gameControllerProvider.notifier)
                      .respondToRematch(game.gameId!, false);
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('Decline'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(gameControllerProvider.notifier)
                      .respondToRematch(game.gameId!, true);
                  // Re-initialize the game after accepting rematch
                  if (mounted) {
                    await _initializeGame();
                  }
                },
                child: const Text('Accept'),
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
          if (game.rematchRequestedBy == currentUserId)
            const Text(
              'Waiting for opponent to accept rematch...',
              style: TextStyle(fontSize: 18, color: Colors.blue),
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
