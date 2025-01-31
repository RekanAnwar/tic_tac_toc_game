import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_state_notifier.dart';
import 'package:tic_tac_toc_game/controllers/online_game_state_notifier.dart';
import 'package:tic_tac_toc_game/models/online_player_model.dart';

class OnlinePlayersList extends ConsumerWidget {
  const OnlinePlayersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlinePlayers = ref.watch(onlineGameControllerProvider);
    final currentUserId = ref.watch(authControllerProvider).value?.id;

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
                    player.email[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(player.email),
                subtitle: Text(player.status.text),
                trailing: player.status == OnlineStatus.online
                    ? ElevatedButton(
                        onPressed: () async {
                          if (currentUserId != null) {
                            try {
                              await ref
                                  .read(onlineGameControllerProvider.notifier)
                                  .sendGameRequest(player.id);

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
