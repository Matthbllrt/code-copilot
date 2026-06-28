import '../models/user_stats.dart';
import '../models/history_entry.dart';
import '../../data/datasources/local/user_local_datasource.dart';

abstract interface class UserRepository {
  Future<UserStats> getStats();
  Future<void> saveStats(UserStats stats);
  Future<Set<String>> getFavorites();
  Future<void> toggleFavorite(String questionId);
  Future<List<HistoryEntry>> getHistory();
  Future<void> addToHistory(HistoryEntry entry);
  Future<void> clearHistory();
  Future<bool> isOnboardingComplete();
  Future<void> setOnboardingComplete();
  Future<ThemeModePreference> getThemeMode();
  Future<void> saveThemeMode(ThemeModePreference mode);
}
