import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/user_stats.dart';
import '../../../domain/models/history_entry.dart';

class UserLocalDatasource {
  const UserLocalDatasource(this._prefs);
  final SharedPreferences _prefs;

  Future<UserStats> getStats() async {
    final json = _prefs.getString(AppConstants.keyStats);
    if (json == null) return const UserStats();
    try {
      return UserStats.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return const UserStats();
    }
  }

  Future<void> saveStats(UserStats stats) async {
    await _prefs.setString(AppConstants.keyStats, jsonEncode(stats.toJson()));
  }

  Future<Set<String>> getFavorites() async {
    final list = _prefs.getStringList(AppConstants.keyFavorites);
    return list?.toSet() ?? {};
  }

  Future<void> saveFavorites(Set<String> ids) async {
    await _prefs.setStringList(AppConstants.keyFavorites, ids.toList());
  }

  Future<List<HistoryEntry>> getHistory() async {
    final jsonList = _prefs.getStringList(AppConstants.keyHistory);
    if (jsonList == null) return [];
    return jsonList
        .map((s) {
          try {
            return HistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<HistoryEntry>()
        .toList();
  }

  Future<void> saveHistory(List<HistoryEntry> entries) async {
    final limited = entries.take(AppConstants.maxHistory).toList();
    final jsonList = limited.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(AppConstants.keyHistory, jsonList);
  }

  Future<bool> isOnboardingComplete() async {
    return _prefs.getBool(AppConstants.keyOnboarding) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(AppConstants.keyOnboarding, true);
  }

  Future<ThemeModePreference> getThemeMode() async {
    final value = _prefs.getString(AppConstants.keyThemeMode);
    return ThemeModePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeModePreference.system,
    );
  }

  Future<void> saveThemeMode(ThemeModePreference mode) async {
    await _prefs.setString(AppConstants.keyThemeMode, mode.name);
  }
}

enum ThemeModePreference { light, dark, system }
