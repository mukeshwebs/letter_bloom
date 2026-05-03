import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme.dart';

class WordTrack extends StatelessWidget {
  final GameState state;
  const WordTrack({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final word = state.currentWord;
    final hasWord = word.isNotEmpty;
    final status = state.liveStatus;

    Color border;
    Color bg;
    Color textColor = Colors.white;
    String? badge;
    IconData? badgeIcon;
    switch (status) {
      case 'goal':
        border = AppColors.leaf;
        bg = AppColors.leaf.withValues(alpha: 0.22);
        badge = 'GOAL';
        badgeIcon = Icons.local_florist;
        break;
      case 'valid':
        border = AppColors.sun;
        bg = AppColors.sun.withValues(alpha: 0.22);
        badge = 'BONUS';
        badgeIcon = Icons.auto_awesome;
        break;
      case 'duplicate':
        border = Colors.white24;
        bg = Colors.white.withValues(alpha: 0.06);
        badge = 'FOUND';
        badgeIcon = Icons.check;
        textColor = Colors.white70;
        break;
      case 'invalid':
        border = Colors.redAccent.withValues(alpha: 0.7);
        bg = Colors.redAccent.withValues(alpha: 0.10);
        textColor = Colors.white70;
        break;
      case 'short':
        border = AppColors.petal.withValues(alpha: 0.5);
        bg = AppColors.petal.withValues(alpha: 0.12);
        textColor = Colors.white70;
        break;
      default:
        border = Colors.white24;
        bg = Colors.white.withValues(alpha: 0.06);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                hasWord ? word : (state.lastMessage ?? 'Swipe letters to spell'),
                style: TextStyle(
                  fontSize: hasWord ? 26 : 14,
                  fontWeight: hasWord ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: hasWord ? 4 : 0.5,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: border.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
