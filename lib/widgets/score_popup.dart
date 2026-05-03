import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme.dart';

/// Listens to [state.pendingScorePops] and floats them up over the grid.
class ScorePopupOverlay extends StatefulWidget {
  final GameState state;
  final Widget child;
  const ScorePopupOverlay({super.key, required this.state, required this.child});

  @override
  State<ScorePopupOverlay> createState() => _ScorePopupOverlayState();
}

class _Pop {
  final int value;
  final bool isGoal;
  final AnimationController controller;
  _Pop({required this.value, required this.isGoal, required this.controller});
}

class _ScorePopupOverlayState extends State<ScorePopupOverlay>
    with TickerProviderStateMixin {
  final List<_Pop> _pops = [];

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onState);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    for (final p in _pops) {
      p.controller.dispose();
    }
    super.dispose();
  }

  void _onState() {
    if (widget.state.pendingScorePops.isEmpty) return;
    final isGoal = widget.state.lastResult == WordResult.acceptedGoal;
    for (final v in List<int>.from(widget.state.pendingScorePops)) {
      final ctl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      );
      final pop = _Pop(value: v, isGoal: isGoal, controller: ctl);
      ctl.forward().whenComplete(() {
        if (!mounted) return;
        setState(() => _pops.remove(pop));
        ctl.dispose();
      });
      setState(() => _pops.add(pop));
    }
    widget.state.pendingScorePops.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        for (final p in _pops)
          AnimatedBuilder(
            animation: p.controller,
            builder: (_, _) {
              final t = p.controller.value;
              return Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -80 * t),
                      child: Opacity(
                        opacity: (1 - t).clamp(0, 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: (p.isGoal ? AppColors.leaf : AppColors.sun)
                                .withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (p.isGoal ? AppColors.leafDeep : AppColors.sunDeep)
                                    .withValues(alpha: 0.6),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            '${p.isGoal ? '🌸 ' : '✨ '}+${p.value}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
