import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme.dart';

class StatsBar extends StatelessWidget {
  final GameState state;
  const StatsBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _Pill(icon: Icons.local_fire_department, label: '${state.streak}', color: AppColors.sun),
          const SizedBox(width: 10),
          _Pill(icon: Icons.flash_on, label: 'x${state.combo}', color: AppColors.petal),
          const Spacer(),
          _Pill(icon: Icons.eco, label: '${state.score}', color: AppColors.leaf, big: true),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool big;
  const _Pill({required this.icon, required this.label, required this.color, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 16 : 12, vertical: big ? 10 : 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: big ? 22 : 18),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: big ? 18 : 14,
              )),
        ],
      ),
    );
  }
}
