import 'hobby_data.dart';

class HobbyUtils {
  /// Parse an arbitrary Firestore value into a list of hobby maps of the
  /// shape `{id, name, emoji, category, custom}`. Every predefined hobby
  /// comes out with a canonical language-neutral `id` — this is what
  /// makes cross-locale matching work.
  ///
  /// Accepted input shapes for each entry:
  ///  - `String` matching a canonical ID (new writes).
  ///  - `String` matching a historical display name in any locale
  ///    (legacy writes like "Hiking" or "Pohodništvo") — normalised to
  ///    the same canonical ID.
  ///  - `String` matching an older translation key like `hobby_running`.
  ///  - `Map` with `id` set (new writes) — enriched from `predefinedHobbies`.
  ///  - `Map` with only `name` set (legacy writes) — routed through the
  ///    legacy-name index.
  ///  - Custom hobbies (`custom: true`) pass through with an empty ID.
  static List<Map<String, dynamic>> parseHobbies(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map<Map<String, dynamic>>((e) {
          if (e is Map) {
            final map = Map<String, dynamic>.from(e);
            final rawId = map['id'] as String?;
            if (rawId != null && rawId.isNotEmpty) {
              final entry = HobbyData.hobbyById(rawId);
              if (entry != null) return Map<String, dynamic>.from(entry);
              // Unknown ID → treat as custom placeholder.
              return {
                'id': rawId,
                'name': (map['name'] as String?) ?? rawId,
                'emoji': (map['emoji'] as String?) ?? '✨',
                'category': (map['category'] as String?) ?? 'Custom',
                'custom': true,
              };
            }
            if (map['custom'] == true) {
              return {
                'id': '',
                'name': (map['name'] as String?) ?? '',
                'emoji': (map['emoji'] as String?) ?? '✨',
                'category': (map['category'] as String?) ?? 'Custom',
                'custom': true,
              };
            }
            final legacyName = map['name'] as String?;
            if (legacyName == null || legacyName.isEmpty)
              return <String, dynamic>{};
            final id = HobbyData.idForLegacyName(legacyName);
            if (id != null) {
              final entry = HobbyData.hobbyById(id);
              if (entry != null) return Map<String, dynamic>.from(entry);
            }
            return {
              'id': '',
              'name': legacyName,
              'emoji': (map['emoji'] as String?) ?? '✨',
              'category': (map['category'] as String?) ?? 'Custom',
              'custom': true,
            };
          }
          if (e is String) {
            if (e.isEmpty) return <String, dynamic>{};
            final id = HobbyData.idForLegacyName(e);
            if (id != null) {
              final entry = HobbyData.hobbyById(id);
              if (entry != null) return Map<String, dynamic>.from(entry);
            }
            return {
              'id': '',
              'name': e,
              'emoji': '✨',
              'category': 'Custom',
              'custom': true,
            };
          }
          return <String, dynamic>{};
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Serialise for Firestore: canonical hobby IDs for predefined
  /// hobbies, verbatim strings for custom ones. Matches the shape the
  /// Cloud Functions compatibility calculator now expects.
  static List<String> toStorage(List<Map<String, dynamic>> hobbies) {
    return hobbies
        .map((h) {
          final id = h['id'] as String?;
          if (id != null && id.isNotEmpty) return id;
          return (h['name'] as String?) ?? '';
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
