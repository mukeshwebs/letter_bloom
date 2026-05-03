import 'dart:async';

import 'package:flutter/material.dart';

import 'models/difficulty.dart';
import 'screens/achievements_screen.dart';
import 'screens/game_screen.dart';
import 'screens/help_screen.dart';
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/levels_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_scope.dart';
import 'services/app_state.dart';
import 'services/firebase_service.dart';
import 'services/storage.dart';
import 'data/dictionary.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final firebase = FirebaseService();
  final state = AppState(Storage(), firebase: firebase);
  await state.bootstrap();
  // Fire-and-forget: bring Firebase + dictionary up in the background.
  // Game-play never blocks on this — local cache + bundled assets are used.
  unawaited(_bootstrapCloud(firebase, state));
  runApp(LetterBloomApp(state: state));
}

Future<void> _bootstrapCloud(FirebaseService fb, AppState state) async {
  await Dictionary.instance.load(); // warm asset/cache
  final ok = await fb.init();
  if (ok) {
    // Sync words + push our scoreboard row.
    await Dictionary.instance.cache.syncFromFirebase(fb);
    await state.syncLeaderboard();
  }
}

class LetterBloomApp extends StatelessWidget {
  final AppState state;
  const LetterBloomApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'LetterBloom',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: '/',
        onGenerateRoute: _route,
      ),
    );
  }

  Route<dynamic> _route(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
        page = const SplashScreen();
        break;
      case '/onboarding':
        page = const OnboardingScreen();
        break;
      case '/home':
        page = const HomeScreen();
        break;
      case '/practice':
        page = const PracticeScreen();
        break;
      case '/profile':
        page = const ProfileScreen();
        break;
      case '/settings':
        page = const SettingsScreen();
        break;
      case '/help':
        page = const HelpScreen();
        break;
      case '/achievements':
        page = const AchievementsScreen();
        break;
      case '/levels':
        page = const LevelsScreen();
        break;
      case '/leaderboard':
        page = const LeaderboardScreen();
        break;
      case '/game/level':
        final lvl = (settings.arguments as int?) ?? 1;
        page = GameScreen(args: GameScreenArgs.level(lvl));
        break;
      case '/game/daily':
        page = const GameScreen(args: GameScreenArgs.daily());
        break;
      case '/game/practice':
        final d = (settings.arguments as Difficulty?) ?? Difficulty.medium;
        page = GameScreen(args: GameScreenArgs.practice(d));
        break;
      default:
        page = const SplashScreen();
    }
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }
}
