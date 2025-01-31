import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
<<<<<<< HEAD
import 'package:tic_tac_toc_game/controllers/auth_controller.dart';
import 'package:tic_tac_toc_game/controllers/online_game_controller.dart';
import 'package:tic_tac_toc_game/views/home/PlayWithAi.dart';
=======
import 'package:tic_tac_toc_game/controllers/accepted_game_request_stream_provider.dart';
import 'package:tic_tac_toc_game/views/home/widgets/game_requests.dart';
>>>>>>> 4c13e4081b96595608ffd7e6f4053aa166c9cb25
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
<<<<<<< HEAD
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
=======
      appBar: AppBar(toolbarHeight: 0),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
>>>>>>> 4c13e4081b96595608ffd7e6f4053aa166c9cb25
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Online Players',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
<<<<<<< HEAD
          Container(
              padding:
                  const EdgeInsets.only(top: 2, bottom: 2, left: 20, right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.blueAccent,
              ),
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TicTacToePage()));
                  },
                  child: const Text(
                    'Play AI',
                    style: TextStyle(color: Colors.white),
                  ))),
          const Expanded(
            child: OnlinePlayersList(),
          ),
=======
          const GameRequests(),
          const OnlinePlayersList(),
>>>>>>> 4c13e4081b96595608ffd7e6f4053aa166c9cb25
        ],
      ),
    );
  }
}
