import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _avatarChoices = ['🌷','🌻','🌵','🌼','🌹','🍀','🌸','🌿','🌱','🌺','🍄','🪴'];

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ScreenScaffold(
      title: 'Profile',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
        children: [
          SectionCard(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _pickAvatar(context),
                  child: Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.petal.withValues(alpha: 0.25),
                      border: Border.all(color: AppColors.petal, width: 2),
                    ),
                    child: Center(
                      child: Text(app.profile.avatarEmoji,
                          style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.profile.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(
                          'Joined ${_fmtDate(app.profile.joined)}',
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit name'),
                        onPressed: () => _editName(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              children: [
                _StatRow(
                    icon: Icons.local_fire_department,
                    label: 'Current streak',
                    value: '${app.streak} day${app.streak == 1 ? '' : 's'}',
                    color: AppColors.sun),
                _StatRow(
                    icon: Icons.emoji_events_outlined,
                    label: 'Longest streak',
                    value: '${app.longestStreak}',
                    color: AppColors.petal),
                _StatRow(
                    icon: Icons.eco,
                    label: 'Words found',
                    value: '${app.stats.totalWords}',
                    color: AppColors.leaf),
                _StatRow(
                    icon: Icons.star_outline,
                    label: 'Total score',
                    value: '${app.stats.totalScore}',
                    color: AppColors.sun),
                _StatRow(
                    icon: Icons.local_florist,
                    label: 'Daily puzzles done',
                    value: '${app.stats.puzzlesCompleted}',
                    color: AppColors.petal),
                _StatRow(
                    icon: Icons.grass,
                    label: 'Practice played',
                    value: '${app.stats.practicePlayed}',
                    color: AppColors.leaf,
                    isLast: true),
              ],
            ),
          ),
          SectionCard(
            onTap: () => Navigator.of(context).pushNamed('/achievements'),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Achievements',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('${app.achievements.length} of 10 unlocked',
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _pickAvatar(BuildContext context) {
    final app = AppScope.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pick an avatar',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in _avatarChoices)
                  GestureDetector(
                    onTap: () async {
                      app.profile.avatarEmoji = e;
                      await app.saveProfile();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: app.profile.avatarEmoji == e
                            ? AppColors.petal.withValues(alpha: 0.4)
                            : Colors.white12,
                        border: Border.all(
                          color: app.profile.avatarEmoji == e ? AppColors.petal : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context) {
    final app = AppScope.of(context);
    final ctrl = TextEditingController(text: app.profile.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgBottom,
        title: const Text('Your name'),
        content: TextField(
          controller: ctrl,
          maxLength: 20,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Gardener'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.petal),
            onPressed: () async {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) {
                app.profile.name = t;
                await app.saveProfile();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 14))),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
