class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  const Achievement(this.id, this.title, this.description, this.emoji);
}

class Achievements {
  static const all = <Achievement>[
    Achievement('first_word',     'First Bloom',     'Find your very first word.', '🌱'),
    Achievement('perfect_garden', 'Perfect Garden',  'Complete a daily puzzle.', '🌷'),
    Achievement('combo3',         'On a Roll',       'Reach a combo of 3.', '⚡'),
    Achievement('combo5',         'Combo Bouquet',   'Reach a combo of 5.', '🌟'),
    Achievement('bonus10',        'Bonus Hunter',    'Find 10 bonus words in one puzzle.', '🍯'),
    Achievement('streak3',        'Three Days',      'Reach a 3-day streak.', '🔥'),
    Achievement('streak7',        'Week of Bloom',   'Reach a 7-day streak.', '🌻'),
    Achievement('all_difficulties','Explorer',       'Try every practice difficulty.', '🧭'),
    Achievement('words100',       'Centurion',       'Find 100 words across all play.', '💯'),
    Achievement('long_word',      'Wordsmith',       'Find a 6+ letter word.', '📖'),
    Achievement('level5',         'Climbing',        'Beat level 5.', '🪜'),
    Achievement('level25',        'High Climber',    'Beat level 25.', '🏔️'),
    Achievement('level100',       'Centennial',      'Beat level 100.', '👑'),
  ];

  static Achievement byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => const Achievement('?', '?', '?', '❓'));
}
