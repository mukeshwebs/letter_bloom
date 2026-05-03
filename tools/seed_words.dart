// tools/seed_words.dart
//
// Uploads the bundled assets/words.txt to Firestore as chunked documents:
//   /dictionary/meta            { version: <epoch>, chunkCount: N }
//   /dictionary/chunk_000000    { words: [...up to 2000 lowercase words...] }
//   /dictionary/chunk_000001    { ... }
//   ...
//
// Run it via the wrapper `tools/firebase_setup.sh`, or standalone:
//
//   gcloud auth application-default login    # one-time
//   dart run tools/seed_words.dart <projectId>
//
// Auth: uses Application Default Credentials. The Firebase CLI's `firebase
// login` already grants them; if not, run `gcloud auth application-default
// login` once.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _chunkSize = 1500;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tools/seed_words.dart <projectId>');
    exit(64);
  }
  final projectId = args.first;

  final words = await _readWords('assets/words.txt');
  print('Read ${words.length} words from assets/words.txt');

  final token = await _accessToken();
  final version = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final chunks = <List<String>>[];
  for (int i = 0; i < words.length; i += _chunkSize) {
    chunks.add(words.sublist(i, (i + _chunkSize).clamp(0, words.length)));
  }
  print('Uploading ${chunks.length} chunks of $_chunkSize words…');

  for (int i = 0; i < chunks.length; i++) {
    final id = 'chunk_${i.toString().padLeft(6, '0')}';
    await _writeDoc(projectId, token, 'dictionary/$id', {
      'words': {
        'arrayValue': {
          'values': [for (final w in chunks[i]) {'stringValue': w}],
        },
      },
    });
    if (i % 10 == 0) print('  …$id (${chunks[i].length} words)');
  }

  await _writeDoc(projectId, token, 'dictionary/meta', {
    'version':    {'integerValue': '$version'},
    'chunkCount': {'integerValue': '${chunks.length}'},
  });
  print('Wrote /dictionary/meta { version: $version, chunkCount: ${chunks.length} }');
  print('✅ Seed complete.');
}

Future<List<String>> _readWords(String path) async {
  final raw = await File(path).readAsString();
  final out = <String>{};
  final re = RegExp(r'^[a-z]+$');
  for (final l in const LineSplitter().convert(raw)) {
    final w = l.trim().toLowerCase();
    if (w.length >= 3 && w.length <= 9 && re.hasMatch(w)) out.add(w);
  }
  return out.toList()..sort();
}

/// Get an OAuth access token from the locally-installed gcloud CLI
/// (or the Firebase CLI as fallback). This avoids a service-account key.
Future<String> _accessToken() async {
  try {
    final r = await Process.run('gcloud', ['auth', 'application-default', 'print-access-token']);
    if (r.exitCode == 0) return (r.stdout as String).trim();
  } catch (_) {}
  try {
    final r = await Process.run('gcloud', ['auth', 'print-access-token']);
    if (r.exitCode == 0) return (r.stdout as String).trim();
  } catch (_) {}
  // Firebase CLI fallback (newer versions expose this).
  final r = await Process.run('firebase', ['auth:print-access-token']);
  if (r.exitCode == 0) return (r.stdout as String).trim();
  throw 'Could not obtain access token. Run: gcloud auth application-default login';
}

Future<void> _writeDoc(
  String projectId,
  String token,
  String path,
  Map<String, dynamic> fields,
) async {
  final parts = path.split('/');
  if (parts.length < 2) throw 'bad path: $path';
  final docId = parts.removeLast();
  final col = parts.join('/');
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$col?documentId=$docId',
  );
  final body = jsonEncode({'fields': fields});
  final client = HttpClient();
  try {
    final req = await client.postUrl(url);
    req.headers.set('Authorization', 'Bearer $token');
    req.headers.contentType = ContentType('application', 'json');
    req.add(utf8.encode(body));
    final resp = await req.close();
    if (resp.statusCode == 409) {
      // Already exists → PATCH (overwrite).
      await _patchDoc(projectId, token, '$col/$docId', fields);
      return;
    }
    if (resp.statusCode >= 300) {
      final txt = await resp.transform(utf8.decoder).join();
      throw 'POST $col/$docId failed: ${resp.statusCode} $txt';
    }
    await resp.drain();
  } finally {
    client.close();
  }
}

Future<void> _patchDoc(
  String projectId,
  String token,
  String path,
  Map<String, dynamic> fields,
) async {
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$path',
  );
  final body = jsonEncode({'fields': fields});
  final client = HttpClient();
  try {
    final req = await client.patchUrl(url);
    req.headers.set('Authorization', 'Bearer $token');
    req.headers.contentType = ContentType('application', 'json');
    req.add(utf8.encode(body));
    final resp = await req.close();
    if (resp.statusCode >= 300) {
      final txt = await resp.transform(utf8.decoder).join();
      throw 'PATCH $path failed: ${resp.statusCode} $txt';
    }
    await resp.drain();
  } finally {
    client.close();
  }
}
