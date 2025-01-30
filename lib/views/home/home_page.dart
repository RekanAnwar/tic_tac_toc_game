import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/online_game_controller.dart';
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
    // ref.listen(acceptedGameRequestProvider, (previous, next) async {
    //   if (next.value != null) {
    //     // Navigate for any valid game request
    //     final gameDoc = await FirebaseFirestore.instance
    //         .collection('games')
    //         .doc(next.value!['gameId'])
    //         .get();

    //     if (gameDoc.exists && context.mounted) {
    //       Navigator.pushReplacementNamed(
    //         context,
    //         '/game',
    //         arguments: next.value,
    //       );
    //     }
    //   }
    // });

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: const OnlinePlayersList(),
    );
  }
}
