import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme.dart';

class GoalWordsPanel extends StatelessWidget {
  final GameState state;
  const GoalWordsPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final goals = state.puzzle.goalWords;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${state.puzzle.themeEmoji}  ${state.puzzle.theme}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              Text('${state.foundGoals.length}/${goals.length}',
                  style: const TextStyle(
                      color: AppColors.leaf, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in goals) _GoalChip(word: g, found: state.foundGoals.contains(g)),
            ],
          ),
          if (state.foundBonus.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Bonus finds',
                style: TextStyle(color: AppColors.sun, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final b in state.foundBonus)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sun.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sun.withValues(alpha: 0.6)),
                    ),
                    child: Text(b.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.sun,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String word;
  final bool found;
  const _GoalChip({required this.word, required this.found});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: found
            ? AppColors.leaf.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: found ? AppColors.leaf : Colors.white24,
          width: 1.4,
        ),
      ),
      child: Text(
        found ? word.toUpperCase() : ('• ' * word.length).trim(),
        style: TextStyle(
          color: found ? Colors.white : AppColors.inkSoft.withValues(alpha: 0.85),
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
