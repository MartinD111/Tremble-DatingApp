import 'package:flutter/material.dart';

/// Wraps [child] so a tap on any empty area unfocuses the active text field
/// (and hides the soft keyboard). Used app-wide via MaterialApp.router's
/// `builder` so every route gets the behaviour without per-screen wiring.
///
/// Uses HitTestBehavior.translucent + a no-op onTap so taps on real interactive
/// children (buttons, list rows, the text field itself) still hit them — only
/// taps that fall through to empty space dismiss the keyboard.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final focus = FocusManager.instance.primaryFocus;
        if (focus != null && focus.hasFocus) focus.unfocus();
      },
      child: child,
    );
  }
}
