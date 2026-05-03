import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_scope.dart';
import '../services/puzzle_generator.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _buildScaffold(context, app),
    );
  }

  Widget _buildScaffold(BuildContext context, app) {
    final today = PuzzleGenerator.forDate(DateTime.now());
    final dayId = today.id;
    final foundList = app.storage.getFoundWords(dayId);
    final found = foundList.length;
    final goalCount = today.goalWords.length;
    final goalsFound = foundList.where(today.goalWords.contains).length;
    final completed = goalCount > 0 && goalsFound == goalCount;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          minimum: const EdgeInsets.only(top: 16),
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            children: [
              _Header(),
              const SizedBox(height: 8),
              _DailyCard(
                theme: today.theme,
                emoji: today.themeEmoji,
                dayId: dayId,
                completed: completed,
                progressLabel: '$found word${found == 1 ? '' : 's'} found',
                goalsFound: goalsFound,
                goalsTotal: goalCount,
                onPlay: () => Navigator.of(context).pushNamed('/game/daily'),
              ),
              SectionCard(
                onTap: () => Navigator.of(context).pushNamed('/practice'),
                child: Row(
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Practice mode',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          SizedBox(height: 2),
                          Text('Unlimited puzzles • 3 difficulties',
                              style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
              Row(children: [
                Expanded(
                    child: SectionCard(
                  margin: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
                  onTap: () => Navigator.of(context).pushNamed('/levels'),
                  child: _MiniTile(
                    emoji: '🗺️',
                    title: 'Levels',
                    subtitle: '∞ • reached Lv ${app.maxLevel == 1 ? 1 : app.maxLevel - 1}',
                  ),
                )),
                Expanded(
                    child: SectionCard(
                  margin: const EdgeInsets.only(left: 6, right: 16, top: 6, bottom: 6),
                  onTap: () => Navigator.of(context).pushNamed('/leaderboard'),
                  child: _MiniTile(
                    emoji: '🏅',
                    title: 'Leaderboard',
                    subtitle: app.firebase.isReady ? 'Global ranks' : 'Cloud off',
                  ),
                )),
              ]),
              Row(children: [
                Expanded(
                    child: SectionCard(
                  margin: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
                  onTap: () => Navigator.of(context).pushNamed('/profile'),
                  child: _MiniTile(
                    emoji: app.profile.avatarEmoji,
                    title: app.profile.name,
                    subtitle: '${app.streak} 🔥 streak',
                  ),
                )),
                Expanded(
                    child: SectionCard(
                  margin: const EdgeInsets.only(left: 6, right: 16, top: 6, bottom: 6),
                  onTap: () => Navigator.of(context).pushNamed('/achievements'),
                  child: _MiniTile(
                    emoji: '🏆',
                    title: 'Badges',
                    subtitle: '${app.achievements.length}/10',
                  ),
                )),
              ]),
              Row(children: [
                Expanded(
                    child: SectionCard(
                  margin: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
                  onTap: () => Navigator.of(context).pushNamed('/help'),
                  child: const _MiniTile(
                    emoji: '❓',
                    title: 'How to play',
                    subtitle: 'Learn the basics',
                  ),
                )),
                Expanded(
                    child: SectionCard(
                  margin: const EdgeInsets.only(left: 6, right: 16, top: 6, bottom: 6),
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                  child: const _MiniTile(
                    emoji: '⚙️',
                    title: 'Settings',
                    subtitle: 'Sound, haptics',
                  ),
                )),
              ]),
              const SizedBox(height: 8),
              SectionCard(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.sun),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'New garden every day at midnight. Same puzzle worldwide.',
                        style: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi ${app.profile.name} ${app.profile.avatarEmoji}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const Text('Ready to bloom today?',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Share LetterBloom',
            icon: const Icon(Icons.ios_share, color: Colors.white),
            onPressed: () {
              final url = app.storage.shareUrl;
              SharePlus.instance.share(ShareParams(
                text: '🌷 LetterBloom — a daily word-bloom puzzle. '
                    'Join me & start your streak!\n$url',
                subject: 'LetterBloom',
              ));
            },
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final String theme;
  final String emoji;
  final String dayId;
  final bool completed;
  final String progressLabel;
  final int goalsFound;
  final int goalsTotal;
  final VoidCallback onPlay;
  const _DailyCard({
    required this.theme,
    required this.emoji,
    required this.dayId,
    required this.completed,
    required this.progressLabel,
    required this.goalsFound,
    required this.goalsTotal,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = goalsTotal == 0 ? 0.0 : goalsFound / goalsTotal;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.petalDeep, AppColors.petal],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.petal.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('TODAY',
                  style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              if (completed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Bloomed ✓',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(theme,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        )),
                    Text(dayId,
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(progressLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text('Goal words: $goalsFound / $goalsTotal',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          PrimaryButton(
            fullWidth: true,
            label: completed ? 'Continue garden' : 'Play today',
            icon: Icons.play_arrow_rounded,
            color: Colors.white,
            foregroundColor: AppColors.petalDeep,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _MiniTile({required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
