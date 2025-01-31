import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_controller.dart';
import 'package:tic_tac_toc_game/controllers/online_game_controller.dart';
import 'package:tic_tac_toc_game/views/home/PlayWithAi.dart';
import 'package:tic_tac_toc_game/views/home/widgets/online_players_list.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkForActiveGame();
  }

  Future<void> _checkForActiveGame() async {
    final gameState = ref.read(acceptedGameRequestProvider);
    if (gameState.value != null) {
      final gameDoc = await FirebaseFirestore.instance
          .collection('games')
          .doc(gameState.value!['gameId'])
          .get();

      if (gameDoc.exists) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/game',
            arguments: gameState.value,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

    // Listen for accepted game requests
    ref.listen(acceptedGameRequestProvider, (previous, next) async {
      if (next.value != null) {
        // Navigate for any valid game request
        final gameDoc = await FirebaseFirestore.instance
            .collection('games')
            .doc(next.value!['gameId'])
            .get();

        if (gameDoc.exists && context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/game',
            arguments: next.value,
          );
        }
      }
    });

    return Scaffold(
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
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome ${user?.email ?? ""}!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
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
        ],
      ),
    );
  }
}
