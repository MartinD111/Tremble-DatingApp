import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<T?> showPlatformDialog<T>({
  required BuildContext context,
  required Widget title,
  required Widget content,
  List<Widget> actions = const [],
  Color? backgroundColor,
  Color? surfaceTintColor,
  ShapeBorder? shape,
  EdgeInsetsGeometry? contentPadding,
  EdgeInsetsGeometry? actionsPadding,
}) {
  if (Platform.isIOS) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: title,
      content: content,
      actions: actions,
      backgroundColor: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
      contentPadding: contentPadding,
      actionsPadding: actionsPadding,
    ),
  );
}

class TrembleAlertDialog extends StatelessWidget {
  const TrembleAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.backgroundColor,
    this.surfaceTintColor,
    this.shape,
    this.contentPadding,
    this.actionsPadding,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: title,
        content: content,
        actions: actions,
      );
    }

    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      backgroundColor: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
      contentPadding: contentPadding,
      actionsPadding: actionsPadding,
    );
  }
}

class TrembleDialogAction extends StatelessWidget {
  const TrembleDialogAction({
    super.key,
    required this.child,
    required this.onPressed,
    this.isDestructive = false,
  });

  final Widget child;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDestructiveAction: isDestructive,
        child: child,
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: isDestructive
          ? TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error)
          : null,
      child: child,
    );
  }
}
