import '../../core/constants/app_constants.dart';
import '../../domain/models/history_entry.dart';
import '../../domain/models/user_stats.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._datasource);
  final UserLocalDatasource _datasource;

  @override
  Future<UserStats> getStats() => _datasource.getStats();

  @override
  Future<void> saveStats(UserStats stats) => _datasource.saveStats(stats);

  @override
  Future<Set<String>> getFavorites() => _datasource.getFavorites();

  @override
  Future<void> toggleFavorite(String questionId) async {
    final favorites = await _datasource.getFavorites();
    if (favorites.contains(questionId)) {
      favorites.remove(questionId);
    } else {
      if (favorites.length >= AppConstants.maxFavorites) {
        throw Exception('Limite de favoris atteinte');
      }
      favorites.add(questionId);
    }
    await _datasource.saveFavorites(favorites);
  }

  @override
  Future<List<HistoryEntry>> getHistory() => _datasource.getHistory();

  @override
  Future<void> addToHistory(HistoryEntry entry) async {
    final history = await _datasource.getHistory();
    history.insert(0, entry);
    await _datasource.saveHistory(history);
  }

  @override
  Future<void> clearHistory() async {
    await _datasource.saveHistory([]);
  }

  @override
  Future<bool> isOnboardingComplete() => _datasource.isOnboardingComplete();

  @override
  Future<void> setOnboardingComplete() => _datasource.setOnboardingComplete();

  @override
  Future<ThemeModePreference> getThemeMode() => _datasource.getThemeMode();

  @override
  Future<void> saveThemeMode(ThemeModePreference mode) =>
      _datasource.saveThemeMode(mode);
}
