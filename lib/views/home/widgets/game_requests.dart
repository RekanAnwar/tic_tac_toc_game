import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/game_request_stream_provider.dart';
import 'package:tic_tac_toc_game/controllers/online_game_async_notifier.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

class GameRequests extends ConsumerWidget {
  const GameRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameRequests = ref.watch(gameRequestsProvider);
    final onlinePlayers = ref.watch(onlineGameAsyncNotifierProvider);

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
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              sender?.email?.substring(0, 1).toUpperCase() ??
                                  '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sender?.displayName ?? 'Unknown Player',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.circle,
                                      color: Colors.green, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Online',
                                    style: TextStyle(
                                        color: Colors.green[700], fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        child: Text(
                          'Do you want to play game with ',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        height: 30,
                        width: double.infinity,
                      ),
                      SizedBox(
                        child: Text(
                          '${sender?.displayName ?? 'Unknown Player'}?',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        height: 30,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8), // Rounded corners
                                side: const BorderSide(
                                    color: Colors.red,
                                    width: 2), // Green border
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 8),
                            ),
                            label: const Text(
                              'Decline',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            onPressed: () async {
                              try {
                                ref
                                    .read(onlineGameAsyncNotifierProvider
                                        .notifier)
                                    .respondToGameRequest(request.id, false);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Failed to decline game request. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  const Color.fromARGB(255, 55, 236, 61),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8), // Rounded corners
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 16, 255, 24),
                                  width: 2,
                                ), // Green border
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 8),
                            ),
                            label: const Text('Accept',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            onPressed: () async {
                              try {
                                ref
                                    .read(onlineGameAsyncNotifierProvider
                                        .notifier)
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
                        ],
                      ),
                    ],
                  ),
                ),
                color: Colors.white,
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
