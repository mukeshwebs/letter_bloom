import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    return ScreenScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
        children: [
          SectionCard(
            child: Column(
              children: [
                _switch('Haptics', 'Vibration on word events',
                    s.hapticsEnabled, Icons.vibration, (v) async {
                  setState(() => s.hapticsEnabled = v);
                  await app.saveSettings();
                }),
                _switch('Sound (placeholder)', 'Toggle in-game audio cues',
                    s.soundEnabled, Icons.volume_up_outlined, (v) async {
                  setState(() => s.soundEnabled = v);
                  await app.saveSettings();
                }),
                _switch('Reduce motion', 'Disable pulsing/animations',
                    s.reduceMotion, Icons.motion_photos_off_outlined, (v) async {
                  setState(() => s.reduceMotion = v);
                  await app.saveSettings();
                }, isLast: true),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                const SizedBox(height: 8),
                Text('LetterBloom v1.0',
                    style: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.9))),
                Text('A daily hex word garden.',
                    style: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.9))),
              ],
            ),
          ),
          SectionCard(
            color: Colors.red.withValues(alpha: 0.12),
            onTap: () => _confirmReset(context),
            child: Row(
              children: const [
                Icon(Icons.delete_outline, color: Colors.redAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Reset all progress',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
                ),
                Icon(Icons.chevron_right, color: Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(String title, String subtitle, bool value, IconData icon,
      ValueChanged<bool> onChanged, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.petal.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.petal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.petal,
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final app = AppScope.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgBottom,
        title: const Text('Reset everything?'),
        content: const Text(
            'This clears your streak, achievements, profile, and all saved progress. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await app.resetAll();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/onboarding', (_) => false);
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
