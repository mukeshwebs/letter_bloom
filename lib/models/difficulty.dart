enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Sprout',
        Difficulty.medium => 'Bloom',
        Difficulty.hard => 'Wildflower',
      };

  String get emoji => switch (this) {
        Difficulty.easy => '🌱',
        Difficulty.medium => '🌷',
        Difficulty.hard => '🌻',
      };

  String get description => switch (this) {
        Difficulty.easy => '7 tiles • 3 short words',
        Difficulty.medium => '19 tiles • 5 themed words',
        Difficulty.hard => '37 tiles • 6 longer words',
      };

  int get radius => switch (this) {
        Difficulty.easy => 1,
        Difficulty.medium => 2,
        Difficulty.hard => 3,
      };

  int get goalCount => switch (this) {
        Difficulty.easy => 3,
        Difficulty.medium => 5,
        Difficulty.hard => 6,
      };

  int get minLen => switch (this) {
        Difficulty.easy => 3,
        Difficulty.medium => 3,
        Difficulty.hard => 4,
      };

  int get maxLen => switch (this) {
        Difficulty.easy => 4,
        Difficulty.medium => 6,
        Difficulty.hard => 7,
      };
}
