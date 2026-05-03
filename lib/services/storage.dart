import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _kStreak = 'streak';
  static const _kLastDay = 'lastDay';
  static const _kLongestStreak = 'longestStreak';
  static const _kFoundPrefix = 'found_';
  static const _kBestScorePrefix = 'best_';
  static const _kOnboardingDone = 'onboardingDone';
  static const _kProfile = 'profile';
  static const _kSettings = 'settings';
  static const _kStats = 'stats';
  static const _kAchievements = 'achievements';
  static const _kTriedPractice = 'triedPractice';
  static const _kMaxLevel = 'maxLevel';
  static const _kLevelBestPrefix = 'levelBest_';
  static const _kShareUrl = 'shareUrl';

  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  // ---- onboarding ----
  bool get onboardingDone => _p.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() async => _p.setBool(_kOnboardingDone, true);

  // ---- streak ----
  int get streak => _p.getInt(_kStreak) ?? 0;
  int get longestStreak => _p.getInt(_kLongestStreak) ?? 0;
  String? get lastDay => _p.getString(_kLastDay);

  Future<int> recordCompletion(String dayId) async {
    final last = _p.getString(_kLastDay);
    int streak = _p.getInt(_kStreak) ?? 0;
    if (last == dayId) return streak;
    if (last != null) {
      final lastDate = DateTime.parse(last);
      final today = DateTime.parse(dayId);
      final diff = today.difference(lastDate).inDays;
      streak = (diff == 1) ? streak + 1 : 1;
    } else {
      streak = 1;
    }
    await _p.setInt(_kStreak, streak);
    await _p.setString(_kLastDay, dayId);
    if (streak > (_p.getInt(_kLongestStreak) ?? 0)) {
      await _p.setInt(_kLongestStreak, streak);
    }
    return streak;
  }

  // ---- per-day found words ----
  List<String> getFoundWords(String dayId) =>
      _p.getStringList('$_kFoundPrefix$dayId') ?? const [];
  Future<void> setFoundWords(String dayId, List<String> words) async =>
      _p.setStringList('$_kFoundPrefix$dayId', words);

  int getBestScore(String dayId) => _p.getInt('$_kBestScorePrefix$dayId') ?? 0;
  Future<void> setBestScore(String dayId, int score) async {
    final cur = _p.getInt('$_kBestScorePrefix$dayId') ?? 0;
    if (score > cur) await _p.setInt('$_kBestScorePrefix$dayId', score);
  }

  // ---- profile ----
  Map<String, dynamic> get profileJson {
    final s = _p.getString(_kProfile);
    if (s == null) return {};
    return Map<String, dynamic>.from(jsonDecode(s) as Map);
  }
  Future<void> setProfile(Map<String, dynamic> data) async =>
      _p.setString(_kProfile, jsonEncode(data));

  // ---- settings ----
  Map<String, dynamic> get settingsJson {
    final s = _p.getString(_kSettings);
    if (s == null) return {};
    return Map<String, dynamic>.from(jsonDecode(s) as Map);
  }
  Future<void> setSettings(Map<String, dynamic> data) async =>
      _p.setString(_kSettings, jsonEncode(data));

  // ---- lifetime stats ----
  Map<String, dynamic> get statsJson {
    final s = _p.getString(_kStats);
    if (s == null) return {};
    return Map<String, dynamic>.from(jsonDecode(s) as Map);
  }
  Future<void> setStats(Map<String, dynamic> data) async =>
      _p.setString(_kStats, jsonEncode(data));

  // ---- achievements ----
  List<String> get achievements => _p.getStringList(_kAchievements) ?? const [];
  Future<void> setAchievements(List<String> ids) async =>
      _p.setStringList(_kAchievements, ids);

  // ---- difficulties tried ----
  List<String> get triedPractice => _p.getStringList(_kTriedPractice) ?? const [];
  Future<void> setTriedPractice(List<String> ids) async =>
      _p.setStringList(_kTriedPractice, ids);

  // ---- levels (1..∞) ----
  /// Highest level the player has either reached or unlocked. Always ≥ 1.
  int get maxLevelReached => _p.getInt(_kMaxLevel) ?? 1;
  Future<void> setMaxLevelReached(int n) async {
    final cur = maxLevelReached;
    if (n > cur) await _p.setInt(_kMaxLevel, n);
  }
  int getLevelBest(int level) => _p.getInt('$_kLevelBestPrefix$level') ?? 0;
  Future<bool> setLevelBest(int level, int score) async {
    final cur = getLevelBest(level);
    if (score > cur) {
      await _p.setInt('$_kLevelBestPrefix$level', score);
      return true;
    }
    return false;
  }

  // ---- share URL (set by setup script after deploy) ----
  String get shareUrl =>
      _p.getString(_kShareUrl) ??
      'https://letterbloom-727346.web.app';
  Future<void> setShareUrl(String url) async => _p.setString(_kShareUrl, url);

  Future<void> resetEverything() async {
    await _p.clear();
  }
}
