import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = <_OnbPage>[
    _OnbPage(
      emoji: '🍯',
      title: 'A garden of letters',
      body: 'Each day, a fresh honeycomb of letters arrives — themed and ready to bloom.',
      color: AppColors.sun,
    ),
    _OnbPage(
      emoji: '👆',
      title: 'Swipe to spell',
      body: 'Drag your finger across adjacent hex tiles to form words. Backtrack anytime.',
      color: AppColors.petal,
    ),
    _OnbPage(
      emoji: '🌷',
      title: 'Find the goal words',
      body: 'Match the day\'s theme to make tiles bloom. Bonus words give extra points.',
      color: AppColors.leaf,
    ),
    _OnbPage(
      emoji: '🔥',
      title: 'Grow your streak',
      body: 'Come back daily to keep your streak alive and unlock achievements.',
      color: AppColors.sun,
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppScope.of(context).storage.setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final on = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: on ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: on ? AppColors.petal : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PrimaryButton(
                  fullWidth: true,
                  label: isLast ? "Let's bloom" : 'Next',
                  icon: isLast ? Icons.local_florist : Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _ctrl.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnbPage p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.color.withValues(alpha: 0.2),
              border: Border.all(color: p.color, width: 2),
            ),
            child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 80))),
          ),
          const SizedBox(height: 32),
          Text(p.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              )),
          const SizedBox(height: 14),
          Text(p.body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _OnbPage {
  final String emoji, title, body;
  final Color color;
  const _OnbPage({required this.emoji, required this.title, required this.body, required this.color});
}
