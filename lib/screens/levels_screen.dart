import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../services/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'game_screen.dart';

/// Infinite paginated level list. Levels 1..maxLevel are unlocked;
/// the next one is "current" and can be played; others are locked.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});
  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  static const _pageSize = 60;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final maxUnlocked = app.maxLevel; // first locked level
        final shown = (maxUnlocked + _pageSize)
            .clamp(_pageSize, 1 << 30); // grow as user advances
        return ScreenScaffold(
          title: 'Levels (∞)',
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Highest reached: Lv ${maxUnlocked == 1 ? 1 : maxUnlocked - 1}  •  Total ${app.stats.totalScore} pts',
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: shown,
                  itemBuilder: (_, i) {
                    final lvl = i + 1;
                    final unlocked = lvl <= maxUnlocked;
                    final best = app.storage.getLevelBest(lvl);
                    return _LevelTile(
                      level: lvl,
                      unlocked: unlocked,
                      bestScore: best,
                      onTap: unlocked
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(
                                    args: GameScreenArgs.level(lvl),
                                  ),
                                ),
                              )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int level;
  final bool unlocked;
  final int bestScore;
  final VoidCallback? onTap;
  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.bestScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final difficulty = level <= 10
        ? Difficulty.easy
        : (level <= 30 ? Difficulty.medium : Difficulty.hard);
    return Material(
      color: unlocked
          ? AppColors.bgBottom.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked
                  ? AppColors.petal.withValues(alpha: 0.4)
                  : Colors.white12,
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(unlocked ? difficulty.emoji : '🔒',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Lv $level',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: unlocked ? Colors.white : Colors.white38)),
              if (unlocked && bestScore > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('★ $bestScore',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sun)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
