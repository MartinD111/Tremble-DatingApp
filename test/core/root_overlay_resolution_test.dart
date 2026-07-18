import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Root-overlay resolution — the mechanism behind the wave-pill fix.
//
// The wave pill inserts an OverlayEntry using the app's root navigator key
// (GoRouter(navigatorKey: rootNavigatorKey)). The presenter USED to grab the
// overlay via Overlay.maybeOf(rootNavigatorKey.currentContext) — which returns
// null, because the root Navigator builds its Overlay as a CHILD, so it is a
// descendant of the navigator's context, and maybeOf walks ancestors. The pill
// therefore never rendered — foreground OR tap — regardless of auth/timing.
//
// The fix reads rootNavigatorKey.currentState.overlay (the Navigator's own
// OverlayState). This test pins both facts so the presenter can't regress back
// to the context lookup.
// ---------------------------------------------------------------------------

void main() {
  testWidgets(
      'Overlay.maybeOf(currentContext) is null, currentState.overlay is not',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: key,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final ctx = key.currentContext;
    expect(ctx, isNotNull);

    // The broken lookup the presenter must never use again.
    expect(
      Overlay.maybeOf(ctx!),
      isNull,
      reason: 'the root Navigator overlay is a descendant, not an ancestor',
    );

    // The correct source the presenter now uses.
    final overlay = key.currentState?.overlay;
    expect(overlay, isNotNull);
    expect(overlay!.mounted, isTrue);
  });

  testWidgets('an OverlayEntry inserted via currentState.overlay renders',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: key,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final overlay = key.currentState!.overlay!;
    overlay.insert(
      OverlayEntry(
        builder: (_) => const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('pill-marker'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('pill-marker'), findsOneWidget);
  });
}
