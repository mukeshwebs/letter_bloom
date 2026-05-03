import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Directory;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

/// Cache-first dictionary backed by:
///   1. Local cache file (downloaded chunk from Firestore)   — preferred
///   2. Bundled `assets/words.txt`                            — fallback / seed
///
/// Refresh policy:
///   - On every cold start, kicks off a background sync.
///   - If Firestore reports a newer `words_version` than what we have
///     cached, downloads chunks and merges into local cache.
///   - Gameplay never blocks on the network: the in-memory set is
///     populated from cache (or assets) immediately.
class WordsCache {
  static const _kVersionKey = 'words_version';
  static const _kSyncedAtKey = 'words_synced_at';
  static const _cacheFilename = 'words_cache.txt';

  final Set<String> _words = {};
  bool _loaded = false;
  Completer<void>? _loading;

  bool get isLoaded => _loaded;
  int get count => _words.length;

  bool contains(String w) => _words.contains(w.toLowerCase());

  /// Loads from cache file if present, otherwise from bundled asset.
  /// Idempotent.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    if (_loading != null) return _loading!.future;
    _loading = Completer<void>();
    try {
      final cached = await _readCacheFile();
      if (cached != null && cached.isNotEmpty) {
        _ingest(cached);
        if (kDebugMode) debugPrint('WordsCache: loaded ${_words.length} from cache');
      } else {
        final asset = await rootBundle.loadString('assets/words.txt');
        _ingest(asset);
        if (kDebugMode) debugPrint('WordsCache: seeded ${_words.length} from asset');
        // Persist asset as initial cache so we don't re-read 873KB next time.
        await _writeCacheFile(asset);
      }
      _loaded = true;
    } finally {
      _loading?.complete();
      _loading = null;
    }
  }

  void _ingest(String content) {
    for (final raw in const LineSplitter().convert(content)) {
      final w = raw.trim().toLowerCase();
      if (w.length >= 3 && w.length <= 9 && RegExp(r'^[a-z]+$').hasMatch(w)) {
        _words.add(w);
      }
    }
  }

  /// Background sync. Safe to call when offline / Firebase not configured.
  Future<void> syncFromFirebase(FirebaseService fb) async {
    if (!fb.isReady) return;
    try {
      final remoteVersion = await fb.fetchDictionaryVersion();
      if (remoteVersion == null) return;
      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getInt(_kVersionKey) ?? 0;
      if (remoteVersion <= localVersion) {
        await prefs.setInt(_kSyncedAtKey, DateTime.now().millisecondsSinceEpoch);
        return;
      }
      final words = await fb.fetchDictionaryChunks();
      if (words.isEmpty) return;
      _words.addAll(words);
      await _writeCacheFile(_words.join('\n'));
      await prefs.setInt(_kVersionKey, remoteVersion);
      await prefs.setInt(_kSyncedAtKey, DateTime.now().millisecondsSinceEpoch);
      if (kDebugMode) {
        debugPrint('WordsCache: synced to v$remoteVersion (${_words.length} words)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('WordsCache sync failed: $e');
    }
  }

  Future<File?> _cacheFile() async {
    if (kIsWeb) return null;
    try {
      final Directory dir = await getApplicationSupportDirectory();
      return File('${dir.path}/$_cacheFilename');
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readCacheFile() async {
    final f = await _cacheFile();
    if (f == null || !await f.exists()) return null;
    return f.readAsString();
  }

  Future<void> _writeCacheFile(String content) async {
    final f = await _cacheFile();
    if (f == null) return;
    await f.writeAsString(content);
  }
}
