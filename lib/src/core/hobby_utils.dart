import 'hobby_data.dart';

class HobbyUtils {
  static List<Map<String, dynamic>> parseHobbies(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value.map((e) {
      if (e is Map) {
        return Map<String, dynamic>.from(e);
      }
      if (e is String) {
        // Try to find it in predefined
        final predefined = HobbyData.predefinedHobbies.firstWhere(
          (h) => h['name'] == e,
          orElse: () => <String, dynamic>{},
        );
        if (predefined.isNotEmpty) {
          return predefined;
        }
        
        // Legacy mapping for old translations
        final legacyMap = {
          'hobby_fitness': 'Fitnes',
          'hobby_pilates': 'Pilates',
          'hobby_walking': 'Pohodništvo',
          'hobby_running': 'Tek',
          'hobby_skiing': 'Smučanje',
          'hobby_snowboarding': 'Bordanje',
          'hobby_climbing': 'Plezanje',
          'hobby_swimming': 'Plavanje',
          'hobby_reading': 'Knjige',
          'hobby_coffee': 'Specialty coffee',
          'hobby_tea': 'Specialty tea',
          'hobby_cooking': 'Kuhanje',
          'hobby_movies': 'Filmi',
          'hobby_series': 'Serije',
          'hobby_video_games': 'Videoigre',
          'hobby_music': 'Glasba', // not in new list, maybe map to something or custom
          'hobby_painting': 'Slikanje',
          'hobby_photography': 'Fotografija',
          'hobby_writing': 'Pisanje', // no match
          'hobby_museums': 'Muzeji',
          'hobby_theater': 'Gledališče', // no match
          'hobby_trips': 'Izleti', // maybe road trips
          'hobby_nature': 'Narava',
          'hobby_mountains': 'Gore',
          'hobby_sea': 'Morje',
          'hobby_city_walks': 'Mestna potepanja',
          'hobby_camping': 'Kampiranje',
        };
        
        final mappedName = legacyMap[e] ?? e;
        final predefinedFallback = HobbyData.predefinedHobbies.firstWhere(
          (h) => h['name'] == mappedName,
          orElse: () => <String, dynamic>{},
        );
        if (predefinedFallback.isNotEmpty) {
          return predefinedFallback;
        }

        return {
          'name': mappedName,
          'emoji': '✨',
          'category': 'Custom',
          'custom': true,
        };
      }
      return <String, dynamic>{};
    }).where((e) => e.isNotEmpty).toList();
  }
}
