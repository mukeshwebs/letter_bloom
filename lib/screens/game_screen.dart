import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/achievements.dart';
import '../data/dictionary.dart';
import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../models/puzzle.dart';
import '../services/app_scope.dart';
import '../services/puzzle_generator.dart';
import '../theme.dart';
import '../widgets/goal_words_panel.dart';
import '../widgets/hex_grid.dart';
import '../widgets/score_popup.dart';
import '../widgets/stats_bar.dart';
import '../widgets/word_track.dart';
import 'package:share_plus/share_plus.dart';

enum GameMode { daily, practice, level }

class GameScreenArgs {
  final GameMode mode;
  final Difficulty? difficulty;
  final int? level;
  const GameScreenArgs.daily()
      : mode = GameMode.daily,
        difficulty = null,
        level = null;
  const GameScreenArgs.practice(this.difficulty)
      : mode = GameMode.practice,
        level = null;
  const GameScreenArgs.level(this.level)
      : mode = GameMode.level,
        difficulty = null;
}

class GameScreen extends StatefulWidget {
  final GameScreenArgs args;
  const GameScreen({super.key, required this.args});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameState? _state;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Dictionary.instance.load();
    if (!mounted) return;
    final app = AppScope.of(context);
    final DailyPuzzle puzzle;
    if (widget.args.mode == GameMode.daily) {
      puzzle = PuzzleGenerator.forDate(DateTime.now());
    } else if (widget.args.mode == GameMode.level) {
      puzzle = PuzzleGenerator.forLevel(widget.args.level ?? 1);
    } else {
      final d = widget.args.difficulty ?? Difficulty.medium;
      puzzle = PuzzleGenerator.practice(d);
      await app.markPracticeTried(d.name);
    }
    final state = GameState(puzzle: puzzle, storage: app.storage, appState: app);
    await state.init();
    setState(() => _state = state);
    state.addListener(_onStateChanged);
    app.addListener(_onAppChanged);
  }

  @override
  void dispose() {
    _state?.removeListener(_onStateChanged);
    if (mounted) {
      try {
        AppScope.of(context).removeListener(_onAppChanged);
      } catch (_) {}
    }
    super.dispose();
  }

  void _onStateChanged() {
    if (_state == null || !mounted) return;
    if (!_celebrated && _state!.dailyComplete) {
      _celebrated = true;
      // Persist + push level completion when in level mode.
      final s = _state!;
      if (s.puzzle.levelNumber != null) {
        AppScope.of(context).recordLevelCompletion(
          level: s.puzzle.levelNumber!,
          score: s.score,
        );
      } else if (!s.puzzle.isPractice) {
        // Daily: also push leaderboard sync.
        AppScope.of(context).syncLeaderboard();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCelebration());
    }
  }

  void _onAppChanged() {
    if (!mounted) return;
    final app = AppScope.of(context);
    if (app.pendingUnlocks.isNotEmpty) {
      final unlocks = List<Achievement>.from(app.pendingUnlocks);
      app.clearPendingUnlocks();
      for (final a in unlocks) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bgBottom,
            duration: const Duration(seconds: 3),
            content: Row(children: [
              Text(a.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Achievement unlocked!',
                        style: TextStyle(color: AppColors.sun, fontWeight: FontWeight.w800)),
                    Text(a.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ]),
          ),
        );
      }
    }
  }

  Future<void> _onSubmit() async {
    if (_state == null) return;
    final r = await _state!.submit();
    if (!mounted) return;
    final hapticsOn = AppScope.of(context).settings.hapticsEnabled;
    if (!hapticsOn) return;
    switch (r) {
      case WordResult.acceptedGoal:
        HapticFeedback.heavyImpact();
        break;
      case WordResult.accepted:
        HapticFeedback.mediumImpact();
        break;
      case WordResult.tooShort:
        break;
      default:
        HapticFeedback.lightImpact();
    }
  }

  void _showCelebration() {
    final s = _state!;
    final isLevel = s.puzzle.levelNumber != null;
    final lvl = s.puzzle.levelNumber;
    String title;
    String sub;
    if (isLevel) {
      title = 'Level $lvl complete!';
      sub = '${PuzzleGenerator.levelLabel(lvl!)} • Theme: ${s.puzzle.theme}';
    } else if (s.puzzle.isPractice) {
      title = 'Practice complete!';
      sub = 'Theme: ${s.puzzle.theme}';
    } else {
      title = 'Garden in full bloom!';
      sub = 'Streak ${s.streak} 🔥';
    }
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: AppColors.bgBottom,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.puzzle.themeEmoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(sub,
                  style: const TextStyle(color: AppColors.sun, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              _ScoreLine(label: 'Score', value: '${s.score}'),
              if (isLevel)
                _ScoreLine(
                  label: 'Best for level',
                  value: '${AppScope.of(context).storage.getLevelBest(lvl!).clamp(s.score, 1 << 30)}',
                ),
              _ScoreLine(label: 'Lifetime', value: '${AppScope.of(context).stats.totalScore}'),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.ios_share, color: Colors.white),
                    label: const Text('Share', style: TextStyle(color: Colors.white)),
                    onPressed: () => _share(s),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('Home', style: TextStyle(color: Colors.white70)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.petal),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (isLevel) {
                        _loadLevel((lvl ?? 0) + 1);
                      } else if (s.puzzle.isPractice) {
                        _restartPractice();
                      }
                    },
                    child: Text(isLevel
                        ? 'Next level →'
                        : (s.puzzle.isPractice ? 'New garden' : 'Keep playing')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share(GameState s) async {
    final app = AppScope.of(context);
    final url = app.storage.shareUrl;
    final mode = s.puzzle.levelNumber != null
        ? 'Level ${s.puzzle.levelNumber}'
        : (s.puzzle.isPractice ? 'Practice' : 'Daily');
    final found = s.foundGoals.length;
    final goals = s.puzzle.goalWords.length;
    final text = '🌷 LetterBloom — $mode (${s.puzzle.theme})\n'
        'Score $found/$goals goals · ${s.score} pts'
        '${s.puzzle.isPractice || s.puzzle.levelNumber != null ? '' : ' · 🔥${s.streak}'}'
        '\nPlay: $url';
    await SharePlus.instance.share(ShareParams(text: text, subject: 'LetterBloom'));
  }

  Future<void> _loadLevel(int level) async {
    final puzzle = PuzzleGenerator.forLevel(level);
    if (!mounted) return;
    final app = AppScope.of(context);
    final state = GameState(puzzle: puzzle, storage: app.storage, appState: app);
    await state.init();
    if (!mounted) return;
    _state?.removeListener(_onStateChanged);
    setState(() {
      _state = state;
      _celebrated = false;
    });
    state.addListener(_onStateChanged);
  }

  Future<void> _restartPractice() async {
    final d = widget.args.difficulty ?? Difficulty.medium;
    final puzzle = PuzzleGenerator.practice(d);
    if (!mounted) return;
    final app = AppScope.of(context);
    final state = GameState(puzzle: puzzle, storage: app.storage, appState: app);
    await state.init();
    if (!mounted) return;
    _state?.removeListener(_onStateChanged);
    setState(() {
      _state = state;
      _celebrated = false;
    });
    state.addListener(_onStateChanged);
  }

  Future<void> _confirmReveal(GameState s) async {
    if (s.revealsUsed >= GameState.maxReveals) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Reveal already used for this puzzle.'),
        ),
      );
      return;
    }
    final unfound = s.puzzle.goalWords.where((w) => !s.foundGoals.contains(w)).length;
    if (unfound == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgBottom,
        title: const Text('Reveal a word?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text(
          'You can fully reveal one goal word per puzzle. No score is awarded for the revealed word.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.petal),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final word = await s.revealWord();
    if (!mounted) return;
    if (word != null) {
      if (AppScope.of(context).settings.hapticsEnabled) {
        HapticFeedback.heavyImpact();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Revealed: ${word.toUpperCase()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: s == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.petal))
              : ListenableBuilder(
                  listenable: s,
                  builder: (_, _) => Column(
                    children: [
                      _Header(
                        state: s,
                        onClear: () => s.cancelSelection(),
                        onNew: s.puzzle.isPractice ? _restartPractice : null,
                        onHint: () {
                          final h = s.useHint();
                          if (h == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                duration: Duration(seconds: 2),
                                content: Text('No hints left.'),
                              ),
                            );
                          }
                        },
                        onReveal: () => _confirmReveal(s),
                      ),
                      StatsBar(state: s),
                      const SizedBox(height: 6),
                      WordTrack(state: s),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ScorePopupOverlay(
                          state: s,
                          child: HexGridWidget(state: s, onSubmit: _onSubmit),
                        ),
                      ),
                      GoalWordsPanel(state: s),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final GameState state;
  final VoidCallback onClear;
  final VoidCallback? onNew;
  final VoidCallback onHint;
  final VoidCallback onReveal;
  const _Header({
    required this.state,
    required this.onClear,
    required this.onHint,
    required this.onReveal,
    this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final hintsLeft = GameState.maxHints - state.hintsUsed;
    final revealsLeft = GameState.maxReveals - state.revealsUsed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.puzzle.levelNumber != null
                      ? 'Level ${state.puzzle.levelNumber}'
                      : (state.puzzle.isPractice ? 'Practice' : 'LetterBloom'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                Text(
                  state.puzzle.levelNumber != null
                      ? '${state.puzzle.theme} • ${state.puzzle.difficulty}'
                      : (state.puzzle.isPractice
                          ? '${state.puzzle.theme} • ${state.puzzle.difficulty}'
                          : 'Daily • ${state.puzzle.id}'),
                  style: TextStyle(
                      fontSize: 12, color: AppColors.inkSoft.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Hint ($hintsLeft left)',
            child: Stack(clipBehavior: Clip.none, children: [
              IconButton(
                icon: Icon(Icons.lightbulb_outline,
                    color: hintsLeft > 0 ? AppColors.sun : Colors.white24),
                onPressed: hintsLeft > 0 ? onHint : null,
              ),
              if (hintsLeft > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.sun,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$hintsLeft',
                        style: const TextStyle(
                            color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
          ),
          if (onNew != null)
            IconButton(
              tooltip: 'New garden',
              icon: const Icon(Icons.shuffle, color: Colors.white70),
              onPressed: onNew,
            ),
          Tooltip(
            message: revealsLeft > 0
                ? 'Reveal a word ($revealsLeft left)'
                : 'Reveal already used',
            child: IconButton(
              icon: Icon(Icons.lock_open_rounded,
                  color: revealsLeft > 0 ? AppColors.petal : Colors.white24),
              onPressed: revealsLeft > 0 ? onReveal : null,
            ),
          ),
          IconButton(
            tooltip: 'Clear selection',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final String label;
  final String value;
  const _ScoreLine({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
