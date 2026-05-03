import 'package:flutter/foundation.dart';

import '../data/dictionary.dart';
import '../services/app_state.dart';
import '../services/storage.dart';
import 'hex.dart';
import 'puzzle.dart';

enum WordResult { tooShort, notInDictionary, alreadyFound, accepted, acceptedGoal }

class GameState extends ChangeNotifier {
  final DailyPuzzle puzzle;
  final Storage storage;
  final AppState? appState;

  final List<Hex> selection = [];
  final Set<String> foundGoals = {};
  final Set<String> foundBonus = {};
  final Set<Hex> bloomedTiles = {};

  int score = 0;
  int combo = 0;
  int streak = 0;

  String? lastMessage;
  WordResult? lastResult;
  bool _completionRecorded = false;
  int hintsUsed = 0;
  static const int maxHints = 3;
  String? revealedHint;

  /// Per-word number of path tiles currently revealed by hints.
  final Map<String, int> _hintLevels = {};
  /// Tiles currently lit up by hints (golden glow on the board).
  final Set<Hex> hintedTiles = {};
  /// Tiny floating "+score" popups pending in the UI.
  final List<int> pendingScorePops = [];

  GameState({required this.puzzle, required this.storage, this.appState});

  Future<void> init() async {
    streak = storage.streak;
    if (!puzzle.isPractice) {
      final saved = storage.getFoundWords(puzzle.id);
      for (final w in saved) {
        if (puzzle.goalWords.contains(w)) {
          foundGoals.add(w);
          // Re-bloom: we don't know exact paths, so mark a tile per-letter occurrence later.
        } else {
          foundBonus.add(w);
        }
        score += _scoreFor(w, isGoal: puzzle.goalWords.contains(w));
      }
      if (foundGoals.length == puzzle.goalWords.length && puzzle.goalWords.isNotEmpty) {
        _completionRecorded = true;
      }
    }
    notifyListeners();
  }

  String get currentWord =>
      selection.map((h) => puzzle.letters[h] ?? '').join().toUpperCase();

  bool isSelected(Hex h) => selection.contains(h);

  void beginSelection(Hex h) {
    selection
      ..clear()
      ..add(h);
    lastMessage = null;
    notifyListeners();
  }

  void extendSelection(Hex h) {
    if (selection.isEmpty) {
      selection.add(h);
      notifyListeners();
      return;
    }
    if (selection.last == h) return;
    if (selection.length >= 2 && selection[selection.length - 2] == h) {
      selection.removeLast();
      notifyListeners();
      return;
    }
    if (selection.contains(h)) return;
    if (!selection.last.neighbors.contains(h)) return;
    selection.add(h);
    notifyListeners();
  }

  void cancelSelection() {
    selection.clear();
    notifyListeners();
  }

  Future<WordResult> submit() async {
    final word = currentWord.toLowerCase();
    WordResult result;
    String message;
    int gained = 0;
    if (word.length < 3) {
      result = WordResult.tooShort;
      message = 'Need ≥ 3 letters';
      combo = 0;
    } else if (foundGoals.contains(word) || foundBonus.contains(word)) {
      result = WordResult.alreadyFound;
      message = 'Already found "$word"';
      combo = 0;
    } else if (!Dictionary.instance.contains(word)) {
      result = WordResult.notInDictionary;
      message = '"$word" not a word';
      combo = 0;
    } else {
      final isGoal = puzzle.goalWords.contains(word);
      combo += 1;
      final base = _scoreFor(word, isGoal: isGoal);
      final mult = combo >= 3 ? 2 : 1;
      gained = base * mult;
      score += gained;
      if (isGoal) {
        foundGoals.add(word);
        bloomedTiles.addAll(selection);
        // Clear any hints that were guiding to this word.
        final path = puzzle.goalPaths[word];
        if (path != null) hintedTiles.removeAll(path);
        result = WordResult.acceptedGoal;
        message = '🌸  +$gained  $word';
      } else {
        foundBonus.add(word);
        result = WordResult.accepted;
        message = '✨  +$gained  $word';
      }
      pendingScorePops.add(gained);
      if (!puzzle.isPractice) {
        await storage.setFoundWords(puzzle.id, [...foundGoals, ...foundBonus]);
        await storage.setBestScore(puzzle.id, score);
      }
      await appState?.onWordFound(len: word.length, combo: combo, scoreAdded: gained);

      if (!_completionRecorded &&
          foundGoals.length == puzzle.goalWords.length &&
          puzzle.goalWords.isNotEmpty) {
        _completionRecorded = true;
        int newStreak = streak;
        if (!puzzle.isPractice) {
          newStreak = await storage.recordCompletion(puzzle.id);
          streak = newStreak;
        }
        await appState?.onPuzzleCompleted(
          bonusCount: foundBonus.length,
          newStreak: newStreak,
          isPractice: puzzle.isPractice,
        );
      }
    }
    lastMessage = message;
    lastResult = result;
    selection.clear();
    notifyListeners();
    return result;
  }

  int _scoreFor(String word, {required bool isGoal}) {
    int base = word.length * 10;
    if (word.length >= 5) base += 20;
    if (word.length >= 6) base += 30;
    if (isGoal) base *= 2;
    return base;
  }

  /// Live status of the current selection — used by WordTrack to colour the bar.
  /// One of: 'empty', 'short', 'invalid', 'duplicate', 'valid', 'goal'.
  String get liveStatus {
    final w = currentWord.toLowerCase();
    if (w.isEmpty) return 'empty';
    if (w.length < 3) return 'short';
    if (foundGoals.contains(w) || foundBonus.contains(w)) return 'duplicate';
    if (!Dictionary.instance.contains(w)) return 'invalid';
    if (puzzle.goalWords.contains(w)) return 'goal';
    return 'valid';
  }

  /// Reveals the next path tile of an unfound goal word as a hint.
  /// First tap: lights the start tile and reveals the length + first letter.
  /// Each subsequent tap on the same word lights another tile + reveals more letters.
  String? useHint() {
    if (hintsUsed >= maxHints) return null;
    final unfound = puzzle.goalWords.where((w) => !foundGoals.contains(w)).toList();
    if (unfound.isEmpty) return null;
    // Prefer the word whose hint has been most progressed but is not yet solved,
    // or otherwise the shortest unfound word.
    unfound.sort((a, b) {
      final la = _hintLevels[a] ?? 0;
      final lb = _hintLevels[b] ?? 0;
      if (la != lb) return lb.compareTo(la);
      return a.length.compareTo(b.length);
    });
    final word = unfound.first;
    final path = puzzle.goalPaths[word];
    if (path == null || path.isEmpty) return null;
    final level = (_hintLevels[word] ?? 0) + 1;
    _hintLevels[word] = level.clamp(1, path.length);
    final reveal = _hintLevels[word]!;
    hintedTiles.addAll(path.take(reveal));
    hintsUsed += 1;
    final masked = StringBuffer();
    for (int i = 0; i < word.length; i++) {
      masked.write(i < reveal ? word[i].toUpperCase() : '•');
    }
    revealedHint = '${word.length}-letter goal: $masked';
    lastMessage = revealedHint;
    notifyListeners();
    return revealedHint;
  }

  bool isHinted(Hex h) => hintedTiles.contains(h);

  bool get dailyComplete =>
      puzzle.goalWords.isNotEmpty &&
      foundGoals.length == puzzle.goalWords.length;
}
