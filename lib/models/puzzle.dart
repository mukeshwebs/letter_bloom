import 'hex.dart';

class DailyPuzzle {
  final DateTime date;
  final String theme;
  final String themeEmoji;
  final Map<Hex, String> letters;
  /// Goal words the player must find to complete the daily.
  final List<String> goalWords;
  /// Path of hex tiles for each goal word (in order of letters), used by hints.
  final Map<String, List<Hex>> goalPaths;
  /// Pangram-like bonus list (extra themed words available on the board).
  final List<String> bonusWords;
  final int radius;
  final String difficulty;
  final bool isPractice;
  /// Non-null when this puzzle was generated for a specific level.
  final int? levelNumber;

  DailyPuzzle({
    required this.date,
    required this.theme,
    required this.themeEmoji,
    required this.letters,
    required this.goalWords,
    required this.bonusWords,
    this.goalPaths = const {},
    this.radius = 2,
    this.difficulty = 'medium',
    this.isPractice = false,
    this.levelNumber,
  });

  String get id {
    if (levelNumber != null) return 'level_$levelNumber';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
