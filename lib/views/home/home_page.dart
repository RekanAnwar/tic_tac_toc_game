import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/online_game_controller.dart';
import 'package:tic_tac_toc_game/views/home/widgets/game_requests.dart';
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
      // final gameDoc = await FirebaseFirestore.instance
      //     .collection('games')
      //     .doc(gameState.value!['gameId'])
      //     .get();

      // if (gameDoc.exists) {
      //   if (mounted) {
      //     Navigator.pushReplacementNamed(
      //       context,
      //       '/game',
      //       arguments: gameState.value,
      //     );
      //   }
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for accepted game requests
    ref.listen(acceptedGameRequestProvider, (previous, next) async {
      if (next.value != null) {
        final game = next.value!;

        if (context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/game',
            arguments: game.toMap(),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
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
        ],
      ),
    );
  }
}
