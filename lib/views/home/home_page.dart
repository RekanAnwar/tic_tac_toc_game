import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/accepted_game_request_stream_provider.dart';
import 'package:tic_tac_toc_game/views/home/widgets/game_requests.dart';
import 'package:tic_tac_toc_game/views/home/widgets/online_players_list.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for accepted game requests
    ref.listen(acceptedGameRequestProvider, (previous, next) async {
      if (next.value != null) {
        final game = next.value!;

        if (context.mounted) {
          Navigator.pushNamed(
            context,
            '/game',
            arguments: game.toMap(),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/game_ai'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Play with AI',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
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
          const GameRequests(),
          const OnlinePlayersList(),
          const SliverToBoxAdapter(
            child: SizedBox(height: kBottomNavigationBarHeight + 20),
          ),
        ],
      ),
    );
  }
}
