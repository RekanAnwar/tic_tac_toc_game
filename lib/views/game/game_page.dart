import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_async_notifier.dart';
import 'package:tic_tac_toc_game/controllers/game_state_notifier.dart';
import 'package:tic_tac_toc_game/controllers/online_game_async_notifier.dart';
import 'package:tic_tac_toc_game/extensions/context_extension.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';
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
        ref
            .read(onlineGameAsyncNotifierProvider.notifier)
            .cleanupGameRequests();
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
    final currentUser = ref.watch(authAsyncNotifierProvider).value!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 0,
          centerTitle: true,
          leading: const SizedBox.shrink(),
          title: const Text('Tic Tac Toe'),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final gameState = ref.watch(gameControllerProvider);
                return gameState.when(
                  data: (gameData) {
                    if (game.gameId != null && !gameData.gameOver) {
                      return IconButton(
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
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(gameControllerProvider.notifier)
                                        .leaveGame(
                                            game.gameId!, currentUser.id!);
                                    if (context.mounted) {
                                      Navigator.pop(context, true);
                                      Navigator.of(context)
                                          .pushReplacementNamed(
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
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            )
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
          // Game over or player left status
          if (game.gameOver || game.playerLeft != null)
            Builder(
              builder: (context) {
                final isWinner = game.winner != null &&
                    ((game.winner == Player.X &&
                            game.player1Id == currentUserId) ||
                        (game.winner == Player.O &&
                            game.player2Id == currentUserId));

                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  color: isWinner
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  child: Column(
                    children: [
                      Text(
                        _getGameStatusText(game, currentUserId),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isWinner ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () async {
                          if (isOnlineGame) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUserId)
                                .update({
                              'status': OnlineStatus.online.toString(),
                            });
                            ref
                                .read(authAsyncNotifierProvider.notifier)
                                .getUser();
                          }
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isWinner ? Colors.green : Colors.red,
                        ),
                        child: const Text('Return to Home'),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          // Existing player info section
          if (isOnlineGame)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('id',
                  whereIn: [game.player1Id, game.player2Id]).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final users = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap({
                          ...doc.data() as Map<String, dynamic>,
                          'id': doc.id,
                        }))
                    .toList();

                final player1 = users.firstWhere(
                  (user) => user.id == game.player1Id,
                  orElse: () =>
                      UserModel(id: game.player1Id, email: 'Player 1'),
                );
                final player2 = users.firstWhere(
                  (user) => user.id == game.player2Id,
                  orElse: () =>
                      UserModel(id: game.player2Id, email: 'Player 2'),
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildPlayerInfo(
                          context,
                          player1,
                          Player.X,
                          game.currentPlayer == Player.X,
                          currentUserId == player1.id,
                        ),
                      ),
                      Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      Expanded(
                        child: _buildPlayerInfo(
                          context,
                          player2,
                          Player.O,
                          game.currentPlayer == Player.O,
                          currentUserId == player2.id,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          // Game board
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

  String _getGameStatusText(GameModel game, String? currentUserId) {
    if (game.playerLeft != null && game.playerLeft != currentUserId) {
      return 'You Won! Opponent Left';
    }

    if (!game.gameOver) return '';

    if (game.winner != null) {
      final isWinner =
          (game.winner == Player.X && game.player1Id == currentUserId) ||
              (game.winner == Player.O && game.player2Id == currentUserId);
      return isWinner ? 'You Won! 🎉' : 'You Lost! 😔';
    }

    return "It's a Draw! 🤝";
  }

  Widget _buildPlayerInfo(
    BuildContext context,
    UserModel player,
    Player symbol,
    bool isCurrentTurn,
    bool isCurrentPlayer,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: isCurrentTurn ? Colors.blue[100] : Colors.grey[200],
          child: Text(
            player.displayName?.substring(0, 1).toUpperCase() ??
                player.email?.substring(0, 1).toUpperCase() ??
                '?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isCurrentTurn ? Colors.blue : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          player.displayName ?? player.email?.split('@')[0] ?? 'Unknown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isCurrentPlayer ? Colors.blue : Colors.grey[800],
          ),
        ),
        Text(
          symbol.toString().split('.').last,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
