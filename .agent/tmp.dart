import 'dart:io';

void main() {
  var file = File('lib/src/features/auth/presentation/registration_flow.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('dart:ui')) {
    content = content.replaceFirst('import \\'package:flutter/material.dart\\';', 'import \\'dart:ui\\';\\nimport \\'package:flutter/material.dart\\';');
  }

  // Find and replace builder: (ctx) => Container(
  content = content.replaceAll(
    'builder: (ctx) => Container(\\n          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),\\n          decoration: BoxDecoration(\\n            color: sheetBg,\\n            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),\\n            border: Border(top: BorderSide(color: borderColor)),\\n          ),',
    'builder: (ctx) => ClipRRect(\\n        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),\\n        child: BackdropFilter(\\n          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),\\n          child: Container(\\n          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),\\n          decoration: BoxDecoration(\\n            color: sheetBg.withValues(alpha: 0.8),\\n            border: Border(top: BorderSide(color: borderColor)),\\n          ),'
  );
  
  content = content.replaceAll(
    'builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {\\n        return SafeArea(\\n          child: Container(\\n            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),\\n            decoration: BoxDecoration(\\n              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,\\n              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),\\n              border: Border(\\n                  top: BorderSide(\\n                      color: isDark ? Colors.white12 : Colors.black12)),\\n            ),',
    'builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {\\n        return SafeArea(\\n          child: ClipRRect(\\n            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),\\n            child: BackdropFilter(\\n              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),\\n              child: Container(\\n            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),\\n            decoration: BoxDecoration(\\n              color: (isDark ? const Color(0xFF1A1A2E) : Colors.white).withValues(alpha: 0.8),\\n              border: Border(\\n                  top: BorderSide(\\n                      color: isDark ? Colors.white12 : Colors.black12)),\\n            ),'
  );

  // We have introduced new nested widgets ClipRRect and BackdropFilter, so we need to add closures at the end of the builder.
  // This is tricky using replaceAll. Better to use regex.
  
  // Actually, I'll use a Dart script with regex to append `),)` when it matches the end of the builder's Container.
  file.writeAsStringSync(content);
}
