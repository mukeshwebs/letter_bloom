import '../services/words_cache.dart';

/// Thin wrapper kept for backwards compatibility. The real storage lives
/// in [WordsCache] which is cache-first (local file > bundled asset > Firestore).
class Dictionary {
  static final Dictionary instance = Dictionary._();
  Dictionary._();

  final WordsCache _cache = WordsCache();
  WordsCache get cache => _cache;

  Future<void> load() => _cache.ensureLoaded();
  bool contains(String word) => _cache.contains(word);
  int get size => _cache.count;
}
