import 'package:flutter/material.dart';
import 'package:tic_tac_toc_game/extensions/context_extension.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/views/game/widgets/animated_game_symbol.dart';

class GameCell extends StatelessWidget {
  const GameCell({
    super.key,
    required this.player,
    required this.onTap,
    this.isWinningCell = false,
  });

  final Player player;
  final VoidCallback onTap;
  final bool isWinningCell;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: isWinningCell ? context.primary.setOpacity(0.1) : null,
          border: Border.all(
            color: context.grey100,
          ),
        ),
        child: Center(
          child: AnimatedGameSymbol(
            player: player,
            size: 50,
          ),
        ),
      ),
    );
  }
}
