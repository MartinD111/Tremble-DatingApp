import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single weekday entry in the radar auto-activation schedule.
///
/// [weekday] follows Dart's `DateTime.weekday` convention:
/// 1 = Monday … 7 = Sunday.
@immutable
class RadarScheduleEntry {
  final int weekday;
  final bool enabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const RadarScheduleEntry({
    required this.weekday,
    required this.enabled,
    required this.startTime,
    required this.endTime,
  });

  RadarScheduleEntry copyWith({
    bool? enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return RadarScheduleEntry(
      weekday: weekday,
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'enabled': enabled,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
      };

  factory RadarScheduleEntry.fromJson(Map<String, dynamic> json) {
    return RadarScheduleEntry(
      weekday: json['weekday'] as int,
      enabled: json['enabled'] as bool? ?? false,
      startTime: TimeOfDay(
        hour: json['startHour'] as int? ?? 9,
        minute: json['startMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int? ?? 17,
        minute: json['endMinute'] as int? ?? 0,
      ),
    );
  }

  /// Default entry for a given weekday — disabled, 09:00–17:00.
  factory RadarScheduleEntry.defaultFor(int weekday) => RadarScheduleEntry(
        weekday: weekday,
        enabled: false,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
      );
}

/// Full weekly radar schedule. Entries are keyed by weekday (1=Mon … 7=Sun).
///
/// By the spec, only Mon–Fri are present by default. The user may add Saturday
/// and/or Sunday on demand via the "+" button in the modal — when added, those
/// weekdays appear as additional entries here.
@immutable
class RadarSchedule {
  final Map<int, RadarScheduleEntry> entries;

  const RadarSchedule(this.entries);

  /// True when at least one entry is enabled — drives the
  /// "Activated" / "Not activated" label in Account Settings.
  bool get isActivated => entries.values.any((e) => e.enabled);

  /// Default schedule: Mon–Fri only, all disabled.
  factory RadarSchedule.defaultSchedule() {
    return RadarSchedule({
      for (int wd = DateTime.monday; wd <= DateTime.friday; wd++)
        wd: RadarScheduleEntry.defaultFor(wd),
    });
  }

  RadarSchedule copyWithEntry(RadarScheduleEntry entry) {
    final next = Map<int, RadarScheduleEntry>.from(entries);
    next[entry.weekday] = entry;
    return RadarSchedule(next);
  }

  RadarSchedule withWeekday(int weekday) {
    if (entries.containsKey(weekday)) return this;
    final next = Map<int, RadarScheduleEntry>.from(entries);
    next[weekday] = RadarScheduleEntry.defaultFor(weekday);
    return RadarSchedule(next);
  }

  RadarSchedule withoutWeekday(int weekday) {
    if (!entries.containsKey(weekday)) return this;
    final next = Map<int, RadarScheduleEntry>.from(entries);
    next.remove(weekday);
    return RadarSchedule(next);
  }

  String toJsonString() {
    final list = entries.values.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  factory RadarSchedule.fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return RadarSchedule.defaultSchedule();
    final map = <int, RadarScheduleEntry>{};
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        final entry = RadarScheduleEntry.fromJson(item);
        map[entry.weekday] = entry;
      } else if (item is Map) {
        final entry =
            RadarScheduleEntry.fromJson(Map<String, dynamic>.from(item));
        map[entry.weekday] = entry;
      }
    }
    if (map.isEmpty) return RadarSchedule.defaultSchedule();
    return RadarSchedule(map);
  }
}

final radarScheduleProvider =
    StateNotifierProvider<RadarScheduleNotifier, RadarSchedule>((ref) {
  return RadarScheduleNotifier();
});

class RadarScheduleNotifier extends StateNotifier<RadarSchedule> {
  static const _key = 'radarSchedule_v1';

  RadarScheduleNotifier() : super(RadarSchedule.defaultSchedule()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || !mounted) return;
    try {
      state = RadarSchedule.fromJsonString(raw);
    } catch (_) {
      // Corrupted payload — fall back to default. Non-fatal.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state.toJsonString());
  }

  Future<void> updateEntry(RadarScheduleEntry entry) async {
    state = state.copyWithEntry(entry);
    await _persist();
  }

  Future<void> replaceAll(RadarSchedule schedule) async {
    state = schedule;
    await _persist();
  }

  Future<void> addWeekday(int weekday) async {
    state = state.withWeekday(weekday);
    await _persist();
  }

  Future<void> removeWeekday(int weekday) async {
    state = state.withoutWeekday(weekday);
    await _persist();
  }
}
