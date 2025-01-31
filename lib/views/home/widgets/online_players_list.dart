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
              child: Text('No players online'),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final player = players[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: player.status.color,
                  child: Text(
                    player.displayName?.substring(0, 1).toUpperCase() ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(player.displayName ?? 'No name'),
                subtitle: Text(player.status.text),
                trailing: player.status == OnlineStatus.online
                    ? ElevatedButton(
                        onPressed: () async {
                          if (currentUserId != null) {
                            try {
                              await ref
                                  .read(
                                      onlineGameAsyncNotifierProvider.notifier)
                                  .sendGameRequest(player.id ?? '');

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Game request sent!'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().split(':')[1]),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Invite to Play'),
                      )
                    : null,
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
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
