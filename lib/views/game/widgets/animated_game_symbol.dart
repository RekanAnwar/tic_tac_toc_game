import 'package:flutter/material.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';

class AnimatedGameSymbol extends StatelessWidget {
  const AnimatedGameSymbol({
    super.key,
    required this.player,
    this.size = 40,
  });

  final Player player;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (player == Player.none) return const SizedBox();

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: player == Player.X ? _buildX() : _buildO(),
    );
  }

  Widget _buildX() {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: -1.0, end: 0.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value * size),
                child: Transform.rotate(
                  angle: 45 * 3.14159 / 180,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    height: 8,
                  ),
                ),
              );
            },
          ),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: -1.0, end: 0.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value * size),
                child: Transform.rotate(
                  angle: -45 * 3.14159 / 180,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    height: 8,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildO() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: -1.0, end: 0.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value * size),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: Colors.transparent,
                width: 8,
              ),
            ),
          ),
        );
      },
    );
  }
}
