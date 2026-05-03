import 'dart:math';

import '../data/themes.dart';
import '../models/difficulty.dart';
import '../models/hex.dart';
import '../models/puzzle.dart';

class PuzzleGenerator {
  /// English letter frequency string used as the filler pool.
  static const _freq = 'eeeeeeeeaaaaaaarrrrrriiiiiitttttoooooonnnnnssssllllccccuuuddpphhggbbffyymmwwkvxzjq';

  /// Builds the daily puzzle for [date] at the given [difficulty] (default medium).
  static DailyPuzzle forDate(DateTime date, {Difficulty difficulty = Difficulty.medium}) {
    final dayKey = DateTime(date.year, date.month, date.day);
    final epochDay = dayKey.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final themes = Themes.themeKeys();
    final theme = themes[epochDay.remainder(themes.length).abs()];
    return _build(
      date: dayKey,
      theme: theme,
      seed: epochDay * 100003,
      difficulty: difficulty,
    );
  }

  /// Builds a freeplay (practice) puzzle. A fresh seed each call.
  static DailyPuzzle practice(Difficulty difficulty, {int? seed, String? theme}) {
    final rngSeed = seed ?? Random().nextInt(1 << 31);
    final themes = Themes.themeKeys();
    final picked = theme ?? themes[Random(rngSeed).nextInt(themes.length)];
    return _build(
      date: DateTime.now(),
      theme: picked,
      seed: rngSeed,
      difficulty: difficulty,
      isPractice: true,
    );
  }

  /// Builds a puzzle for an arbitrary level number (1..∞).
  /// Difficulty scales smoothly:
  ///   levels 1–10  → easy   (radius 1, 7 tiles, 3-letter words)
  ///   levels 11–30 → medium (radius 2, 19 tiles, themed)
  ///   levels 31–80 → hard   (radius 3, 37 tiles, longer words)
  ///   levels 81+   → hard with progressively longer/more goals
  static DailyPuzzle forLevel(int level) {
    assert(level >= 1);
    final difficulty = _difficultyForLevel(level);
    final themes = Themes.themeKeys();
    final theme = themes[(level - 1) % themes.length];
    final seed = level * 9973 + 17;
    return _build(
      date: DateTime.now(),
      theme: theme,
      seed: seed,
      difficulty: difficulty,
      isPractice: false,
      levelNumber: level,
    );
  }

  static Difficulty _difficultyForLevel(int level) {
    if (level <= 10) return Difficulty.easy;
    if (level <= 30) return Difficulty.medium;
    return Difficulty.hard;
  }

  /// Human label for a level (e.g. "Sprout • Lv 4").
  static String levelLabel(int level) {
    final d = _difficultyForLevel(level);
    return '${d.label} • Lv $level';
  }

  static DailyPuzzle _build({
    required DateTime date,
    required String theme,
    required int seed,
    required Difficulty difficulty,
    bool isPractice = false,
    int? levelNumber,
  }) {
    final board = Hex.hexagon(difficulty.radius);
    final adj = {for (final h in board) h: h.neighbors.where(board.contains).toList()};

    for (int attempt = 0; attempt < 12; attempt++) {
      final rng = Random(seed + attempt * 7919);
      final result = _tryGenerate(theme, rng, board, adj, difficulty);
      if (result != null) {
        return DailyPuzzle(
          date: date,
          theme: theme,
          themeEmoji: themeEmoji(theme),
          letters: result.$1,
          goalWords: result.$2,
          goalPaths: result.$3,
          bonusWords: const [],
          radius: difficulty.radius,
          difficulty: difficulty.name,
          isPractice: isPractice,
          levelNumber: levelNumber,
        );
      }
    }
    return DailyPuzzle(
      date: date,
      theme: theme,
      themeEmoji: themeEmoji(theme),
      letters: _randomFill(Random(seed), {}, board: board),
      goalWords: const [],
      bonusWords: const [],
      radius: difficulty.radius,
      difficulty: difficulty.name,
      isPractice: isPractice,
      levelNumber: levelNumber,
    );
  }

  static String themeEmoji(String theme) {
    switch (theme) {
      case 'Garden': return '🌷';
      case 'Ocean':  return '🌊';
      case 'Space':  return '🌌';
      case 'Cozy':   return '🫖';
      case 'Forest': return '🌲';
      case 'Bakery': return '🥐';
      case 'Storm':  return '⛈️';
      case 'Citrus': return '🍋';
      default:       return '✨';
    }
  }

  static (Map<Hex, String>, List<String>, Map<String, List<Hex>>)? _tryGenerate(
    String theme,
    Random rng,
    List<Hex> board,
    Map<Hex, List<Hex>> adj,
    Difficulty difficulty,
  ) {
    final pool = (Themes.sets[theme] ?? const <String>[])
        .map((w) => w.toLowerCase())
        .where((w) => w.length >= difficulty.minLen && w.length <= difficulty.maxLen)
        .toList()
      ..shuffle(rng);

    final placed = <Hex, String>{};
    final goals = <String>[];
    final paths = <String, List<Hex>>{};

    for (final word in pool) {
      if (goals.length >= difficulty.goalCount) break;
      if (word.length > board.length) continue;
      final snapshot = Map<Hex, String>.from(placed);
      final path = _placeWord(word, placed, rng, board, adj);
      if (path != null) {
        goals.add(word);
        paths[word] = path;
      } else {
        placed
          ..clear()
          ..addAll(snapshot);
      }
    }

    final minGoals = difficulty == Difficulty.easy ? 2 : 3;
    if (goals.length < minGoals) return null;

    final filled = _randomFill(rng, placed, themeWords: pool, board: board);
    return (filled, goals, paths);
  }

  static List<Hex>? _placeWord(
    String word,
    Map<Hex, String> placed,
    Random rng,
    List<Hex> board,
    Map<Hex, List<Hex>> adj,
  ) {
    final cells = List<Hex>.from(board)..shuffle(rng);
    for (final start in cells) {
      final existing = placed[start];
      if (existing != null && existing != word[0]) continue;
      final path = <Hex>[start];
      final added = <Hex, String>{};
      if (placed[start] == null) added[start] = word[0];
      if (_dfs(word, 1, path, placed, added, rng, adj)) {
        placed.addAll(added);
        return List<Hex>.from(path);
      }
    }
    return null;
  }

  static bool _dfs(
    String word,
    int idx,
    List<Hex> path,
    Map<Hex, String> placed,
    Map<Hex, String> added,
    Random rng,
    Map<Hex, List<Hex>> adj,
  ) {
    if (idx == word.length) return true;
    final wantedChar = word[idx];
    final neigh = List<Hex>.from(adj[path.last]!)..shuffle(rng);
    for (final n in neigh) {
      if (path.contains(n)) continue;
      final cur = placed[n] ?? added[n];
      if (cur != null && cur != wantedChar) continue;
      final wasAdded = !added.containsKey(n) && placed[n] == null;
      if (wasAdded) added[n] = wantedChar;
      path.add(n);
      if (_dfs(word, idx + 1, path, placed, added, rng, adj)) return true;
      path.removeLast();
      if (wasAdded) added.remove(n);
    }
    return false;
  }

  static Map<Hex, String> _randomFill(
    Random rng,
    Map<Hex, String> placed, {
    List<String> themeWords = const [],
    required List<Hex> board,
  }) {
    final out = Map<Hex, String>.from(placed);
    final pool = StringBuffer(_freq);
    for (final w in themeWords) {
      pool..write(w)..write(w);
    }
    final s = pool.toString();
    for (final h in board) {
      if (out.containsKey(h)) continue;
      out[h] = s[rng.nextInt(s.length)];
    }
    return out;
  }
}
