# 🌸 LetterBloom — Daily Word Garden

A unique Flutter word puzzle inspired by word search, but played on a **hexagonal honeycomb grid** with a fresh **daily-themed puzzle** for everyone.

## How to play

- **Swipe** across adjacent honeycomb tiles to spell a word.
- The puzzle has a **theme of the day** (Garden, Ocean, Storm, Cozy, Bakery, Citrus, Forest, Space). Find the **goal words** to complete today's garden.
- Any other valid English word ≥ 3 letters earns **bonus points** ✨
- Find words back-to-back without missing to build a **combo x2 multiplier** ⚡
- Goal-word tiles **bloom** 🌷 — they keep their letters and can be re-used in other words.
- Come back every day to grow your **streak** 🔥

## Design highlights

| Layer | Implementation |
|-------|---------------|
| Grid  | 19 hex tiles (radius-2 axial coordinates) drawn with `CustomPainter` |
| Input | Single `GestureDetector` with nearest-tile hit-testing for fluid swipe selection (with backtrack) |
| Daily puzzle | Date-seeded RNG → theme pick → backtracking DFS to lay 3-5 themed words on hex paths → frequency-weighted filler letters |
| Dictionary | ~105k common English words bundled as an asset |
| Persistence | `shared_preferences` for streak, daily-best, and found words |
| Visuals | Animated pulsing selection, blooming petal decorations on completed tiles, gradient backgrounds, Fredoka font |

## Project layout

```
lib/
  main.dart
  theme.dart
  models/      hex.dart, puzzle.dart, game_state.dart
  data/        dictionary.dart, themes.dart
  services/    puzzle_generator.dart, storage.dart
  widgets/     hex_grid.dart, word_track.dart, goal_words_panel.dart, stats_bar.dart
  screens/     game_screen.dart
assets/
  words.txt    (filtered system dictionary, 3-9 letter words)
```

## Run

```sh
flutter pub get
flutter run            # iOS / Android / desktop
flutter build web      # static web build
```
