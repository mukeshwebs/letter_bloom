import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    final app = AppScope.of(context, listen: false);
    // Push our latest score before reading.
    app.syncLeaderboard();
    _future = app.firebase.topLeaderboard(limit: 100);
  }

  Future<void> _refresh() async {
    final app = AppScope.of(context, listen: false);
    await app.syncLeaderboard();
    setState(() {
      _future = app.firebase.topLeaderboard(limit: 100);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cloudReady = app.firebase.isReady;

    return ScreenScaffold(
      title: 'Leaderboard',
      body: !cloudReady
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('🌐', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text(
                      'Cloud not configured',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Run tools/firebase_setup.sh once to enable the global leaderboard with anonymous sign-in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkSoft, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.petal,
              onRefresh: _refresh,
              child: FutureBuilder<List<LeaderboardEntry>>(
                future: _future,
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.petal),
                    );
                  }
                  final list = snap.data ?? const <LeaderboardEntry>[];
                  if (list.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text('No scores yet — be the first!',
                              style: TextStyle(color: AppColors.inkSoft)),
                        ),
                      ],
                    );
                  }
                  final me = app.firebase.uid;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final e = list[i];
                      final mine = e.uid == me;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: mine
                              ? AppColors.petal.withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: mine ? AppColors.petal : Colors.white12,
                              width: mine ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: i < 3 ? AppColors.sun : Colors.white70)),
                            ),
                            Text(e.avatar, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mine ? '${e.name}  (you)' : e.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                      'Lv ${e.levelsBeat}  •  🔥${e.longestStreak}',
                                      style: const TextStyle(
                                          color: AppColors.inkSoft, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('${e.totalScore}',
                                style: const TextStyle(
                                    color: AppColors.sun,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
