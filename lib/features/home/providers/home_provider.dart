import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/user_stats.dart';
import '../../../domain/models/badge_model.dart';
import '../../../domain/models/history_entry.dart';
import '../../../domain/repositories/question_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../data/repositories/question_repository_impl.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../data/datasources/local/user_local_datasource.dart';
import '../../../core/constants/app_constants.dart';

// ===== Infrastructure providers =====

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final userLocalDatasourceProvider = Provider<UserLocalDatasource>((ref) {
  return UserLocalDatasource(ref.watch(sharedPreferencesProvider));
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return const QuestionRepositoryImpl();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userLocalDatasourceProvider));
});

// ===== User Stats =====

class UserStatsNotifier extends AsyncNotifier<UserStats> {
  @override
  Future<UserStats> build() async {
    return ref.read(userRepositoryProvider).getStats();
  }

  Future<void> addXp(int amount) async {
    final current = state.valueOrNull ?? const UserStats();
    final newXp = current.xpPoints + amount;
    final newLevel = _calculateLevel(newXp);
    final updated = current.copyWith(xpPoints: newXp, level: newLevel);
    state = AsyncData(updated);
    await ref.read(userRepositoryProvider).saveStats(updated);
  }

  Future<void> recordQuestion(String categoryId) async {
    final current = state.valueOrNull ?? const UserStats();
    final byCategory = Map<String, int>.from(current.questionsByCategory);
    byCategory[categoryId] = (byCategory[categoryId] ?? 0) + 1;

    final lastSession = current.lastSessionDate;
    final now = DateTime.now();
    int newStreak = current.currentStreak;
    if (lastSession != null) {
      final diff = now.difference(lastSession).inDays;
      if (diff == 1) {
        newStreak++;
      } else if (diff > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final updated = current.copyWith(
      totalQuestionsAnswered: current.totalQuestionsAnswered + 1,
      questionsByCategory: byCategory,
      currentStreak: newStreak,
      bestStreak: newStreak > current.bestStreak ? newStreak : current.bestStreak,
      lastSessionDate: now,
      firstSessionDate: current.firstSessionDate ?? now,
      xpPoints: current.xpPoints + AppConstants.xpPerQuestion,
      level: _calculateLevel(current.xpPoints + AppConstants.xpPerQuestion),
    );
    state = AsyncData(updated);
    await ref.read(userRepositoryProvider).saveStats(updated);
    await _checkBadges(updated);
  }

  Future<void> recordSession(String mode) async {
    final current = state.valueOrNull ?? const UserStats();
    final byMode = Map<String, int>.from(current.sessionsByMode);
    byMode[mode] = (byMode[mode] ?? 0) + 1;
    final updated = current.copyWith(
      totalSessions: current.totalSessions + 1,
      sessionsByMode: byMode,
      xpPoints: current.xpPoints + AppConstants.xpPerSession,
      level: _calculateLevel(current.xpPoints + AppConstants.xpPerSession),
    );
    state = AsyncData(updated);
    await ref.read(userRepositoryProvider).saveStats(updated);
  }

  Future<void> recordShare() async {
    final current = state.valueOrNull ?? const UserStats();
    final updated = current.copyWith(
      totalShares: current.totalShares + 1,
      xpPoints: current.xpPoints + AppConstants.xpPerShare,
      level: _calculateLevel(current.xpPoints + AppConstants.xpPerShare),
    );
    state = AsyncData(updated);
    await ref.read(userRepositoryProvider).saveStats(updated);
  }

  Future<void> recordFavorite(bool added) async {
    final current = state.valueOrNull ?? const UserStats();
    final updated = current.copyWith(
      totalFavorites: added
          ? current.totalFavorites + 1
          : (current.totalFavorites - 1).clamp(0, 9999),
      xpPoints: added
          ? current.xpPoints + AppConstants.xpPerFavorite
          : current.xpPoints,
    );
    state = AsyncData(updated);
    await ref.read(userRepositoryProvider).saveStats(updated);
  }

  Future<void> resetStats() async {
    const fresh = UserStats();
    state = const AsyncData(UserStats());
    await ref.read(userRepositoryProvider).saveStats(fresh);
  }

  Future<void> _checkBadges(UserStats stats) async {
    final newBadges = <String>[];
    for (final badge in BadgeModel.allBadges) {
      if (stats.earnedBadgeIds.contains(badge.id)) continue;
      if (_isBadgeEarned(badge, stats)) {
        newBadges.add(badge.id);
      }
    }
    if (newBadges.isEmpty) return;
    final updated = stats.copyWith(
      earnedBadgeIds: [...stats.earnedBadgeIds, ...newBadges],
    );
    state = AsyncData(updated);
    await ref.read(userRepositoryProvider).saveStats(updated);
  }

  bool _isBadgeEarned(BadgeModel badge, UserStats stats) {
    switch (badge.id) {
      case 'first_question': return stats.totalQuestionsAnswered >= 1;
      case 'ten_questions': return stats.totalQuestionsAnswered >= 10;
      case 'fifty_questions': return stats.totalQuestionsAnswered >= 50;
      case 'hundred_questions': return stats.totalQuestionsAnswered >= 100;
      case 'five_hundred_questions': return stats.totalQuestionsAnswered >= 500;
      case 'thousand_questions': return stats.totalQuestionsAnswered >= 1000;
      case 'first_session': return stats.totalSessions >= 1;
      case 'ten_sessions': return stats.totalSessions >= 10;
      case 'fifty_sessions': return stats.totalSessions >= 50;
      case 'streak_3': return stats.currentStreak >= 3;
      case 'streak_7': return stats.currentStreak >= 7;
      case 'streak_30': return stats.currentStreak >= 30;
      case 'first_favorite': return stats.totalFavorites >= 1;
      case 'twenty_favorites': return stats.totalFavorites >= 20;
      case 'first_share': return stats.totalShares >= 1;
      case 'all_categories':
        return stats.questionsByCategory.length >= 9;
      case 'level_5': return stats.level >= 5;
      case 'level_10': return stats.level >= 10;
      default: return false;
    }
  }

  int _calculateLevel(int xp) {
    const thresholds = [0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 12000, 17000, 24000, 33000, 45000, 60000];
    int level = 1;
    for (int i = 1; i < thresholds.length; i++) {
      if (xp >= thresholds[i]) level = i + 1;
    }
    return level.clamp(1, thresholds.length);
  }
}

final userStatsProvider = AsyncNotifierProvider<UserStatsNotifier, UserStats>(
  UserStatsNotifier.new,
);

// ===== Favorites =====

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    return ref.read(userRepositoryProvider).getFavorites();
  }

  Future<void> toggle(String questionId) async {
    final current = state.valueOrNull ?? {};
    final isFav = current.contains(questionId);
    await ref.read(userRepositoryProvider).toggleFavorite(questionId);
    if (isFav) {
      state = AsyncData({...current}..remove(questionId));
    } else {
      state = AsyncData({...current, questionId});
    }
    await ref.read(userStatsProvider.notifier).recordFavorite(!isFav);
  }

  bool isFavorite(String questionId) =>
      state.valueOrNull?.contains(questionId) ?? false;
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

// ===== Theme =====

class ThemeNotifier extends AsyncNotifier<ThemeModePreference> {
  @override
  Future<ThemeModePreference> build() async {
    return ref.read(userRepositoryProvider).getThemeMode();
  }

  Future<void> setTheme(ThemeModePreference mode) async {
    state = AsyncData(mode);
    await ref.read(userRepositoryProvider).saveThemeMode(mode);
  }
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeModePreference>(
  ThemeNotifier.new,
);

// ===== History =====

class HistoryNotifier extends AsyncNotifier<List<HistoryEntry>> {
  @override
  Future<List<HistoryEntry>> build() async {
    return ref.read(userRepositoryProvider).getHistory();
  }

  Future<void> add(HistoryEntry entry) async {
    await ref.read(userRepositoryProvider).addToHistory(entry);
    final current = state.valueOrNull ?? [];
    state = AsyncData([entry, ...current]);
  }

  Future<void> clear() async {
    await ref.read(userRepositoryProvider).clearHistory();
    state = const AsyncData([]);
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<HistoryEntry>>(
  HistoryNotifier.new,
);

// ===== Categories =====

final categoriesProvider = Provider<List<QuestionCategory>>((ref) {
  return QuestionCategory.allCategories;
});
