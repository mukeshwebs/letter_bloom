import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Practice',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'Pick a difficulty for an unlimited freeplay puzzle.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          for (final d in Difficulty.values) _LevelCard(d: d),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Difficulty d;
  const _LevelCard({required this.d});

  Color get _color => switch (d) {
        Difficulty.easy => AppColors.leaf,
        Difficulty.medium => AppColors.petal,
        Difficulty.hard => AppColors.sun,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).pushNamed('/game/practice', arguments: d),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_color.withValues(alpha: 0.85), _color.withValues(alpha: 0.45)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _color.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(d.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.label,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(d.description,
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}
