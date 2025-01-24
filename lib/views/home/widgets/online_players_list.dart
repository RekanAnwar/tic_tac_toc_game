import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/online_game_controller.dart';
import 'package:tic_tac_toc_game/models/online_player_model.dart';

class OnlinePlayersList extends ConsumerWidget {
  const OnlinePlayersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlinePlayers = ref.watch(onlineGameControllerProvider);
    final gameRequests = ref.watch(gameRequestsProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Online Players',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        gameRequests.when(
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
                    orElse: () => OnlinePlayerModel(
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
                          sender?.email[0].toUpperCase() ?? '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                          'Game Request from ${sender?.email ?? 'Unknown Player'}'),
                      subtitle: const Text('Would you like to play a game?'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green, size: 32),
                            onPressed: () {
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
                            icon: const Icon(Icons.cancel,
                                color: Colors.red, size: 32),
                            onPressed: () {
                              try {
                                ref
                                    .read(onlineGameControllerProvider.notifier)
                                    .respondToGameRequest(request.id, false);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Failed to reject game request. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
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
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SliverToBoxAdapter(
            child: Center(
              child: Text('Error loading game requests: $error'),
            ),
          ),
        ),
        onlinePlayers.when(
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
                      backgroundColor: _getStatusColor(player.status),
                      child: Text(
                        player.email[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(player.email),
                    subtitle: Text(_getStatusText(player.status)),
                    trailing: player.status == OnlineStatus.online
                        ? ElevatedButton(
                            onPressed: () {
                              if (currentUserId != null) {
                                try {
                                  ref
                                      .read(onlineGameControllerProvider.notifier)
                                      .sendGameRequest(player.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Game request sent!'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Failed to send game request. Please try again.'),
                                      backgroundColor: Colors.red,
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
        ),
      ],
    );
  }

  Color _getStatusColor(OnlineStatus status) {
    switch (status) {
      case OnlineStatus.online:
        return Colors.green;
      case OnlineStatus.inGame:
        return Colors.orange;
      case OnlineStatus.offline:
        return Colors.grey;
    }
  }

  String _getStatusText(OnlineStatus status) {
    switch (status) {
      case OnlineStatus.online:
        return 'Online';
      case OnlineStatus.inGame:
        return 'In Game';
      case OnlineStatus.offline:
        return 'Offline';
    }
  }
}
