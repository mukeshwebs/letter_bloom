import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// One score row for the global leaderboard.
class LeaderboardEntry {
  final String uid;
  final String name;
  final String avatar;
  final int totalScore;
  final int levelsBeat;
  final int longestStreak;
  final DateTime updated;

  LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.avatar,
    required this.totalScore,
    required this.levelsBeat,
    required this.longestStreak,
    required this.updated,
  });

  factory LeaderboardEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return LeaderboardEntry(
      uid: doc.id,
      name: (d['name'] as String?) ?? 'Player',
      avatar: (d['avatar'] as String?) ?? '🌷',
      totalScore: (d['totalScore'] as num?)?.toInt() ?? 0,
      levelsBeat: (d['levelsBeat'] as num?)?.toInt() ?? 0,
      longestStreak: (d['longestStreak'] as num?)?.toInt() ?? 0,
      updated: (d['updated'] is Timestamp)
          ? (d['updated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

/// Daily theme override pulled from Firestore. Lets you ship a hand-curated
/// theme/word list without app updates.
class DailyConfig {
  final String date; // YYYY-MM-DD
  final String? themeOverride;
  final List<String> bonusFeatured;
  DailyConfig({required this.date, this.themeOverride, this.bonusFeatured = const []});
}

class FirebaseService {
  bool _initialized = false;
  bool _ready = false;
  String? _error;
  String? _uid;

  bool get isReady => _ready;
  String? get error => _error;
  String? get uid => _uid;
  bool get isAnonymous => _ready && (FirebaseAuth.instance.currentUser?.isAnonymous ?? false);

  /// Resolves to true if Firebase + anonymous auth came up successfully.
  /// Never throws — failures degrade to offline mode.
  Future<bool> init() async {
    if (_initialized) return _ready;
    _initialized = true;
    final opts = DefaultFirebaseOptions.currentPlatform;
    if (opts == null) {
      _error = 'Firebase not configured (run tools/firebase_setup.sh).';
      if (kDebugMode) debugPrint('FirebaseService: $_error');
      return false;
    }
    try {
      await Firebase.initializeApp(options: opts);
      final cred = FirebaseAuth.instance.currentUser ??
          (await FirebaseAuth.instance.signInAnonymously()).user;
      _uid = cred?.uid;
      _ready = true;
      if (kDebugMode) debugPrint('FirebaseService: ready uid=$_uid');
      return true;
    } catch (e) {
      _error = 'Firebase init failed: $e';
      if (kDebugMode) debugPrint(_error!);
      return false;
    }
  }

  // ---------- Dictionary ----------

  /// Reads the meta document at `dictionary/meta`. Expected shape:
  ///   `{ version: <int>, chunkCount: <int> }`
  Future<int?> fetchDictionaryVersion() async {
    if (!_ready) return null;
    final snap = await FirebaseFirestore.instance
        .collection('dictionary')
        .doc('meta')
        .get();
    final v = snap.data()?['version'];
    return v is num ? v.toInt() : null;
  }

  /// Reads chunks `dictionary/chunk_000000`..`chunk_NNNNNN` and concatenates
  /// their `words: [..]` arrays. Returns lowercase words.
  Future<List<String>> fetchDictionaryChunks() async {
    if (!_ready) return const [];
    final col = await FirebaseFirestore.instance
        .collection('dictionary')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'chunk_')
        .where(FieldPath.documentId, isLessThan: 'chunk_~')
        .get();
    final out = <String>[];
    for (final d in col.docs) {
      final words = d.data()['words'];
      if (words is List) {
        for (final w in words) {
          if (w is String) out.add(w.toLowerCase());
        }
      }
    }
    return out;
  }

  // ---------- Daily config ----------

  Future<DailyConfig?> fetchDailyConfig(String dateId) async {
    if (!_ready) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('daily')
          .doc(dateId)
          .get();
      if (!doc.exists) return null;
      final d = doc.data()!;
      return DailyConfig(
        date: dateId,
        themeOverride: d['theme'] as String?,
        bonusFeatured: ((d['featured'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  // ---------- Leaderboard ----------

  /// Upserts the player's row in `/leaderboard/{uid}`.
  Future<void> upsertLeaderboard({
    required String name,
    required String avatar,
    required int totalScore,
    required int levelsBeat,
    required int longestStreak,
  }) async {
    if (!_ready || _uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('leaderboard').doc(_uid).set({
        'name': name,
        'avatar': avatar,
        'totalScore': totalScore,
        'levelsBeat': levelsBeat,
        'longestStreak': longestStreak,
        'updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('upsertLeaderboard failed: $e');
    }
  }

  Future<List<LeaderboardEntry>> topLeaderboard({int limit = 50}) async {
    if (!_ready) return const [];
    try {
      final q = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('totalScore', descending: true)
          .limit(limit)
          .get();
      return q.docs.map(LeaderboardEntry.fromDoc).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('topLeaderboard failed: $e');
      return const [];
    }
  }

  /// Records a level completion under `/levels/{level}/scores/{uid}`.
  Future<void> recordLevelScore({required int level, required int score}) async {
    if (!_ready || _uid == null) return;
    try {
      final ref = FirebaseFirestore.instance
          .collection('levels')
          .doc('$level')
          .collection('scores')
          .doc(_uid);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final cur = await tx.get(ref);
        final prev = (cur.data()?['score'] as num?)?.toInt() ?? 0;
        if (score > prev) {
          tx.set(ref, {
            'score': score,
            'updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('recordLevelScore failed: $e');
    }
  }
}
