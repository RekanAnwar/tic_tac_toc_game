import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/current_index_state_provider.dart';
import 'package:tic_tac_toc_game/views/home/home_page.dart';
import 'package:tic_tac_toc_game/views/profile/profile_page.dart';
import 'package:tic_tac_toc_game/views/rank/rank_page.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final List<Widget> _pages = const [
    HomePage(),
    RankPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    final currentIndexNotifier = ref.read(currentIndexProvider.notifier);

    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => currentIndexNotifier.state = index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.games),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard),
            label: 'Rank',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
