import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/game_request_stream_provider.dart';
import 'package:tic_tac_toc_game/controllers/online_game_state_notifier.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

class GameRequests extends ConsumerWidget {
  const GameRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameRequests = ref.watch(gameRequestsProvider);
    final onlinePlayers = ref.watch(onlineGameControllerProvider);

    return gameRequests.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final request = requests[index];

              final sender = onlinePlayers.value?.firstWhere(
                (player) => player.id == request.fromPlayerId,
                orElse: () => UserModel(
                  id: request.fromPlayerId,
                  email: 'Unknown Player',
                ),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      sender?.email?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    'Game Request from ${sender?.email ?? 'Unknown Player'}',
                  ),
                  subtitle: const Text('Would you like to play a game?'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green, size: 32),
                        onPressed: () async {
                          try {
                            ref
                                .read(onlineGameControllerProvider.notifier)
                                .respondToGameRequest(request.id, true);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to accept game request. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          try {
                            ref
                                .read(onlineGameControllerProvider.notifier)
                                .respondToGameRequest(request.id, false);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Failed to reject game request. Please try again.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: requests.length,
          ),
        );
      },
      error: (error, stackTrace) =>
          const SliverToBoxAdapter(child: SizedBox.shrink()),
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}
