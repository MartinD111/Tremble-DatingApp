---
paths:
  - "**/*.dart"
---
# Dart/Flutter Coding Style

> This file extends common/coding-style.md with Dart and Flutter specific content.

## Immutability

Prefer `const` constructors and `final` fields everywhere:

```dart
// WRONG: Mutable widget state
class UserCard extends StatelessWidget {
  String name;         // mutable!
  Color color;

  UserCard(this.name, this.color);
}

// CORRECT: const + final
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) { ... }
}
```

Use `const` widget constructors everywhere Flutter allows it — this enables compile-time constant folding and skips rebuilds.

## Naming Conventions

Follow [Effective Dart naming](https://dart.dev/effective-dart/style):

| Type | Convention | Example |
|------|-----------|---------|
| Classes, enums, typedefs | UpperCamelCase | `RadarViewModel` |
| Variables, parameters, functions | lowerCamelCase | `isScanning` |
| Constants | lowerCamelCase | `maxRadarDuration` |
| Files | snake_case | `radar_screen.dart` |
| Packages | snake_case | `tremble_core` |

## Error Handling

Never swallow exceptions. Always surface errors meaningfully:

```dart
// WRONG: Silent failure
try {
  await firestore.collection('users').doc(uid).set(data);
} catch (_) {}

// CORRECT: Log + rethrow or return typed result
try {
  await firestore.collection('users').doc(uid).set(data);
} catch (e, stack) {
  debugPrint('[UserRepo] update failed: $e');
  debugPrintStack(stackTrace: stack);
  rethrow;
}
```

Use sealed classes or `Result<T, E>` pattern for recoverable errors:

```dart
sealed class RadarResult {}
class RadarSuccess extends RadarResult { final List<NearbyUser> users; ... }
class RadarError extends RadarResult { final String message; ... }
```

## Async Patterns

Always `await` Futures; never fire-and-forget without explicit intent:

```dart
// WRONG: Fire-and-forget loses errors
void onButtonTap() {
  fetchData(); // silently fails on error
}

// CORRECT: Handle in async context
void onButtonTap() {
  unawaited(_handleTap()); // explicit fire-and-forget
}

Future<void> _handleTap() async {
  try {
    await fetchData();
  } catch (e) {
    _showError(e);
  }
}
```

Use `unawaited()` from `dart:async` to make intentional fire-and-forget explicit.

## Widget Architecture

Follow feature-first folder structure:

```
lib/
  features/
    radar/
      data/          # repositories, data sources
      domain/        # models, use cases
      presentation/  # screens, widgets, view models
    profile/
    matches/
  core/
    services/        # BLE, location, Firebase wrappers
    widgets/         # shared UI components
    utils/
```

Keep widgets small — if `build()` exceeds ~60 lines, extract sub-widgets.

## State Management (Riverpod)

Use `@riverpod` code generation for all providers:

```dart
// CORRECT: Annotated provider with code gen
@riverpod
Future<List<NearbyUser>> nearbyUsers(NearbyUsersRef ref) async {
  final radarService = ref.watch(radarServiceProvider);
  return radarService.getNearbyUsers();
}

// CORRECT: Notifier for mutable state
@riverpod
class RadarNotifier extends _$RadarNotifier {
  @override
  RadarState build() => const RadarState.idle();

  Future<void> startScan() async { ... }
  void stop() => state = const RadarState.idle();
}
```

Never use `setState` outside of truly local UI state (e.g., animation controllers).

## Console / Logging

- No `print()` in production code — use `debugPrint()` for development, a logging package for production
- Prefix log messages with module context: `[RadarService]`, `[AuthRepo]`
- Strip debug logs before release builds using `kDebugMode` guards:

```dart
if (kDebugMode) {
  debugPrint('[AppCheck] debug token: $token');
}
```
