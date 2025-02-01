import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_async_notifier.dart';
import 'package:tic_tac_toc_game/controllers/online_game_async_notifier.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

class OnlinePlayersList extends ConsumerWidget {
  const OnlinePlayersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlinePlayers = ref.watch(onlineGameAsyncNotifierProvider);
    final currentUserId = ref.watch(authAsyncNotifierProvider).value?.id;

    return onlinePlayers.when(
      data: (players) {
        if (players.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'No players online',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final player = players[index];
              final isOnline = player.status == OnlineStatus.online;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: isOnline ? Colors.green : Colors.red,
                    child: Text(
                      (player.displayName?.isNotEmpty ?? false)
                          ? player.displayName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    player.displayName ?? 'Unknown Player',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        isOnline ? Icons.circle : Icons.circle,
                        color: isOnline ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        player.status.text,
                        style: TextStyle(
                          color: isOnline ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: isOnline
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            if (currentUserId == null) return;

                            try {
                              await ref
                                  .read(
                                      onlineGameAsyncNotifierProvider.notifier)
                                  .sendGameRequest(player.id ?? '');

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Game request sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error: ${e.toString().split(':').last.trim()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Invite'),
                        )
                      : null,
                ),
              );
            },
            childCount: players.length,
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => SliverFillRemaining(
        child: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
