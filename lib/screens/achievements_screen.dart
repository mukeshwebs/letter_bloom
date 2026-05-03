import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../services/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ScreenScaffold(
      title: 'Achievements',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Text('${app.achievements.length} of ${Achievements.all.length} unlocked',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: [
              for (final a in Achievements.all)
                _Badge(achievement: a, unlocked: app.achievements.contains(a.id)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _Badge({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.sun.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? AppColors.sun : Colors.white12,
          width: unlocked ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: unlocked ? 1.0 : 0.35,
            child: Text(achievement.emoji, style: const TextStyle(fontSize: 38)),
          ),
          const SizedBox(height: 8),
          Text(achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white60,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.inkSoft.withValues(alpha: 0.8), fontSize: 11)),
        ],
      ),
    );
  }
}
