import 'dart:io';

void main() {
  final file = File('lib/src/features/auth/presentation/registration_flow.dart');
  String content = file.readAsStringSync();
  
  // Make sure dart:ui is available for ImageFilter
  if (!content.contains("import 'dart:ui';")) {
    content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'dart:ui';\\nimport 'package:flutter/material.dart';");
  }

  // Common pattern for simple builder: (ctx) => Container
  final simplePattern = RegExp(r'builder:\s*\(ctx\)\s*=>\s*Container\(\s*padding:\s*const\s*EdgeInsets\.fromLTRB\(24,\s*12,\s*24,\s*40\),\s*decoration:\s*BoxDecoration\(\s*color:\s*(.+?),\s*borderRadius:\s*const\s*BorderRadius\.vertical\(top:\s*Radius\.circular\(28\)\),\s*border:\s*Border\(top:\s*BorderSide\(color:\s*(.+?)\)\),\s*\),');
  
  content = content.replaceAllMapped(simplePattern, (match) {
    var bgCode = match.group(1)!;
    var borderCode = match.group(2)!;
    return 'builder: (ctx) => ClipRRect('
        '\\n        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),'
        '\\n        child: BackdropFilter('
        '\\n          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),'
        '\\n          child: Container('
        '\\n            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),'
        '\\n            decoration: BoxDecoration('
        '\\n              color: ($bgCode).withValues(alpha: 0.8),'
        '\\n              border: Border(top: BorderSide(color: $borderCode)),'
        '\\n            ),';
  });

  // A different pattern for StatefulBuilder
  final statefulPattern = RegExp(r'builder:\s*\(ctx\)\s*=>\s*StatefulBuilder\(builder:\s*\(ctx,\s*setModalState\)\s*\{\s*return\s*SafeArea\(\s*child:\s*Container\(\s*padding:\s*const\s*EdgeInsets\.fromLTRB\(24,\s*12,\s*24,\s*40\),\s*decoration:\s*BoxDecoration\(\s*color:\s*(.+?),\s*borderRadius:\s*const\s*BorderRadius\.vertical\(top:\s*Radius\.circular\(28\)\),\s*border:\s*Border\(\s*top:\s*BorderSide\(\s*color:\s*(.+?)\)\),\s*\),');

  content = content.replaceAllMapped(statefulPattern, (match) {
    var bgCode = match.group(1)!;
    var borderCode = match.group(2)!;
    return 'builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {\\n        return SafeArea(\\n          child: ClipRRect(\\n            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),\\n            child: BackdropFilter(\\n              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),\\n              child: Container(\\n                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),\\n                decoration: BoxDecoration(\\n                  color: ($bgCode).withValues(alpha: 0.8),\\n                  border: Border(\\n                    top: BorderSide(\\n                      color: $borderCode)),\\n                ),';
  });
  
  // Wait, I replaced the Container but the Container had a closing `)` at the end of the method!
  // It's much safer to replace only the beginning, and then at the end of each `showModalBottomSheet` add the missing `),)`.
  // Actually, I can just replace `) \n        )` with `) \n        )))` for the end of `Builder` or just fix compilation errors using a second script iteration.
  
  file.writeAsStringSync(content);
}
