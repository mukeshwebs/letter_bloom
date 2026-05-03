import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _items = [
    _Tip('🍯', 'The board',
        'Each daily puzzle is a hex honeycomb of letters arranged around a daily theme.'),
    _Tip('👆', 'Spell by swiping',
        'Press a tile and drag through neighbouring tiles. Drag back over the previous tile to undo a step.'),
    _Tip('🌷', 'Goal words',
        'Find every themed goal word to complete the daily garden. Their tiles bloom and become reusable.'),
    _Tip('✨', 'Bonus words',
        'Any English word ≥ 3 letters earns bonus points, even if it isn\'t a goal word.'),
    _Tip('⚡', 'Combos',
        'Find words back-to-back without an invalid attempt. Combo x3+ doubles every score.'),
    _Tip('🔥', 'Streak',
        'Complete a daily puzzle to grow your streak. Skip a day and it resets to one.'),
    _Tip('🌱', 'Practice mode',
        'Want more? Practice has unlimited freeplay puzzles in three sizes — Sprout, Bloom, Wildflower.'),
    _Tip('🏆', 'Achievements',
        'Unlock badges by completing puzzles, hitting combos, finding long words, and growing your streak.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'How to play',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
        children: [
          for (final t in _items) SectionCard(child: _TipRow(t)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tip: longer words score way more — and 6+ letter words unlock a hidden badge.',
                style: TextStyle(
                    color: AppColors.inkSoft.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

class _Tip {
  final String emoji, title, body;
  const _Tip(this.emoji, this.title, this.body);
}

class _TipRow extends StatelessWidget {
  final _Tip tip;
  const _TipRow(this.tip);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tip.emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tip.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text(tip.body,
                  style: TextStyle(
                      color: AppColors.inkSoft.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
