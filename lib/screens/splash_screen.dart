import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../widgets/common.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    Future.delayed(const Duration(milliseconds: 1300), _route);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _route() {
    if (!mounted) return;
    final app = AppScope.of(context);
    final skip = Uri.base.queryParameters['skipOnboarding'] == '1';
    Navigator.of(context).pushReplacementNamed(
      (app.storage.onboardingDone || skip) ? '/home' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('🌸', style: TextStyle(fontSize: 96)),
                SizedBox(height: 12),
                Text('LetterBloom',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    )),
                SizedBox(height: 8),
                Text('A daily word garden',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
