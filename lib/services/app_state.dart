import 'package:flutter/foundation.dart';

import '../data/achievements.dart';
import 'firebase_service.dart';
import 'storage.dart';

class UserProfile {
  String name;
  String avatarEmoji;
  DateTime joined;

  UserProfile({required this.name, required this.avatarEmoji, required this.joined});

  factory UserProfile.defaults() => UserProfile(
        name: 'Gardener',
        avatarEmoji: '🌷',
        joined: DateTime.now(),
      );

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: (j['name'] as String?) ?? 'Gardener',
        avatarEmoji: (j['avatarEmoji'] as String?) ?? '🌷',
        joined: DateTime.tryParse((j['joined'] as String?) ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarEmoji': avatarEmoji,
        'joined': joined.toIso8601String(),
      };
}

class AppSettings {
  bool hapticsEnabled;
  bool soundEnabled;
  bool reduceMotion;

  AppSettings({this.hapticsEnabled = true, this.soundEnabled = true, this.reduceMotion = false});

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        hapticsEnabled: (j['hapticsEnabled'] as bool?) ?? true,
        soundEnabled: (j['soundEnabled'] as bool?) ?? true,
        reduceMotion: (j['reduceMotion'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'hapticsEnabled': hapticsEnabled,
        'soundEnabled': soundEnabled,
        'reduceMotion': reduceMotion,
      };
}

class LifetimeStats {
  int totalWords;
  int totalScore;
  int puzzlesCompleted;
  int practicePlayed;

  LifetimeStats({
    this.totalWords = 0,
    this.totalScore = 0,
    this.puzzlesCompleted = 0,
    this.practicePlayed = 0,
  });

  factory LifetimeStats.fromJson(Map<String, dynamic> j) => LifetimeStats(
        totalWords: (j['totalWords'] as int?) ?? 0,
        totalScore: (j['totalScore'] as int?) ?? 0,
        puzzlesCompleted: (j['puzzlesCompleted'] as int?) ?? 0,
        practicePlayed: (j['practicePlayed'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'totalWords': totalWords,
        'totalScore': totalScore,
        'puzzlesCompleted': puzzlesCompleted,
        'practicePlayed': practicePlayed,
      };
}

/// Root, app-wide reactive state. Holds profile, settings, lifetime stats,
/// streak, achievements. Persisted via [Storage].
class AppState extends ChangeNotifier {
  final Storage storage;
  final FirebaseService firebase;

  late UserProfile profile;
  late AppSettings settings;
  late LifetimeStats stats;
  late int streak;
  late int longestStreak;
  late Set<String> achievements;
  late Set<String> triedDifficulties;
  late int maxLevel;
  int levelsBeat = 0;

  /// Newly-unlocked achievements pending UI toast.
  final List<Achievement> pendingUnlocks = [];

  AppState(this.storage, {FirebaseService? firebase})
      : firebase = firebase ?? FirebaseService();

  Future<void> bootstrap() async {
    final p = storage.profileJson;
    profile = p.isEmpty ? UserProfile.defaults() : UserProfile.fromJson(p);
    settings = AppSettings.fromJson(storage.settingsJson);
    stats = LifetimeStats.fromJson(storage.statsJson);
    streak = storage.streak;
    longestStreak = storage.longestStreak;
    achievements = storage.achievements.toSet();
    triedDifficulties = storage.triedPractice.toSet();
    maxLevel = storage.maxLevelReached;
    levelsBeat = (maxLevel - 1).clamp(0, 1 << 30);
    if (p.isEmpty) await storage.setProfile(profile.toJson());
  }

  /// Sync a level-completion result.
  /// Returns true if it was a new best for that level.
  Future<bool> recordLevelCompletion({required int level, required int score}) async {
    final newBest = await storage.setLevelBest(level, score);
    if (level + 1 > maxLevel) {
      maxLevel = level + 1;
      levelsBeat = level;
      await storage.setMaxLevelReached(maxLevel);
    } else if (level > levelsBeat) {
      levelsBeat = level;
    }
    if (level >= 5) _maybeUnlock('level5');
    if (level >= 25) _maybeUnlock('level25');
    if (level >= 100) _maybeUnlock('level100');
    notifyListeners();
    // Best-effort cloud sync.
    await firebase.recordLevelScore(level: level, score: score);
    await syncLeaderboard();
    return newBest;
  }

  /// Pushes the current player's totals to the cloud leaderboard.
  Future<void> syncLeaderboard() async {
    if (!firebase.isReady) return;
    await firebase.upsertLeaderboard(
      name: profile.name,
      avatar: profile.avatarEmoji,
      totalScore: stats.totalScore,
      levelsBeat: levelsBeat,
      longestStreak: longestStreak,
    );
  }

  Future<void> saveProfile() async {
    await storage.setProfile(profile.toJson());
    notifyListeners();
  }

  Future<void> saveSettings() async {
    await storage.setSettings(settings.toJson());
    notifyListeners();
  }

  Future<void> saveStats() async {
    await storage.setStats(stats.toJson());
    notifyListeners();
  }

  Future<void> markPracticeTried(String difficulty) async {
    if (triedDifficulties.add(difficulty)) {
      await storage.setTriedPractice(triedDifficulties.toList());
      _checkAchievements();
      notifyListeners();
    }
  }

  /// Update lifetime stats after a word is found in any puzzle.
  Future<void> onWordFound({required int len, required int combo, required int scoreAdded}) async {
    stats.totalWords += 1;
    stats.totalScore += scoreAdded;
    await saveStats();
    _maybeUnlock('first_word');
    if (len >= 6) _maybeUnlock('long_word');
    if (combo >= 3) _maybeUnlock('combo3');
    if (combo >= 5) _maybeUnlock('combo5');
    if (stats.totalWords >= 100) _maybeUnlock('words100');
    _checkAchievements();
    if (pendingUnlocks.isNotEmpty) notifyListeners();
  }

  Future<void> onPuzzleCompleted({
    required int bonusCount,
    required int newStreak,
    required bool isPractice,
  }) async {
    if (isPractice) {
      stats.practicePlayed += 1;
    } else {
      stats.puzzlesCompleted += 1;
      streak = newStreak;
      if (newStreak > longestStreak) longestStreak = newStreak;
      _maybeUnlock('perfect_garden');
      if (newStreak >= 3) _maybeUnlock('streak3');
      if (newStreak >= 7) _maybeUnlock('streak7');
    }
    if (bonusCount >= 10) _maybeUnlock('bonus10');
    await saveStats();
    notifyListeners();
  }

  void _maybeUnlock(String id) {
    if (achievements.contains(id)) return;
    achievements.add(id);
    pendingUnlocks.add(Achievements.byId(id));
    storage.setAchievements(achievements.toList());
  }

  void _checkAchievements() {
    if (triedDifficulties.length >= 3) _maybeUnlock('all_difficulties');
  }

  void clearPendingUnlocks() {
    pendingUnlocks.clear();
    notifyListeners();
  }

  Future<void> resetAll() async {
    await storage.resetEverything();
    profile = UserProfile.defaults();
    settings = AppSettings();
    stats = LifetimeStats();
    streak = 0;
    longestStreak = 0;
    achievements = {};
    triedDifficulties = {};
    pendingUnlocks.clear();
    await storage.setProfile(profile.toJson());
    notifyListeners();
  }
}
