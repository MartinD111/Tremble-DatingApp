import 'dart:io';

void main() {
  final file = File('lib/src/features/settings/presentation/settings_screen.dart');
  var text = file.readAsStringSync();
  
  text = text.replaceAll(
    'backgroundColor: Colors.white.withValues(alpha: 0.1)',
    'backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)',
  );
  
  text = text.replaceAll(
    'color: Colors.white, fontWeight: FontWeight.bold',
    'color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold',
  );
  
  text = text.replaceAll(
    'isSelected ? Colors.pinkAccent : Colors.white24',
    'isSelected ? Colors.pinkAccent : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12)',
  );

  text = text.replaceAll(
    'activeTrackColor: Colors.grey[800],',
    'activeTrackColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[400],',
  );

  text = text.replaceAll(
    'inactiveTrackColor: Colors.white24,',
    'inactiveTrackColor: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12,',
  );

  file.writeAsStringSync(text);
  print('Replaced content effectively');
}
