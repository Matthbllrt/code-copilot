import 'package:equatable/equatable.dart';
import 'game_session.dart';

class UserStats extends Equatable {
  final int totalQuestionsAnswered;
  final int totalSessions;
  final int totalFavorites;
  final int totalShares;
  final int currentStreak;
  final int bestStreak;
  final int xpPoints;
  final int level;
  final Map<String, int> questionsByCategory;
  final Map<String, int> sessionsByMode;
  final DateTime? lastSessionDate;
  final DateTime? firstSessionDate;
  final List<String> earnedBadgeIds;
  final List<String> earnedAchievementIds;

  const UserStats({
    this.totalQuestionsAnswered = 0,
    this.totalSessions = 0,
    this.totalFavorites = 0,
    this.totalShares = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.xpPoints = 0,
    this.level = 1,
    this.questionsByCategory = const {},
    this.sessionsByMode = const {},
    this.lastSessionDate,
    this.firstSessionDate,
    this.earnedBadgeIds = const [],
    this.earnedAchievementIds = const [],
  });

  String get levelTitle {
    if (level <= 2) return 'Explorateurs';
    if (level <= 4) return 'Complices';
    if (level <= 6) return 'Amoureux';
    if (level <= 8) return 'Âmes Sœurs';
    if (level <= 10) return 'Inséparables';
    if (level <= 12) return 'Légendaires';
    return 'Mythiques';
  }

  int get xpForNextLevel {
    const thresholds = [0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 12000, 17000, 24000, 33000, 45000, 60000];
    if (level >= thresholds.length) return 0;
    return thresholds[level] - xpPoints;
  }

  double get levelProgress {
    const thresholds = [0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 12000, 17000, 24000, 33000, 45000, 60000];
    if (level >= thresholds.length) return 1.0;
    final currentLevelXp = thresholds[level - 1];
    final nextLevelXp = thresholds[level];
    if (nextLevelXp <= currentLevelXp) return 1.0;
    return (xpPoints - currentLevelXp) / (nextLevelXp - currentLevelXp);
  }

  String get favoriteCategory {
    if (questionsByCategory.isEmpty) return 'Aucune';
    final sorted = questionsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  GameMode? get favoriteMode {
    if (sessionsByMode.isEmpty) return null;
    final sorted = sessionsByMode.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    try {
      return GameMode.values.firstWhere((m) => m.name == sorted.first.key);
    } catch (_) {
      return null;
    }
  }

  UserStats copyWith({
    int? totalQuestionsAnswered,
    int? totalSessions,
    int? totalFavorites,
    int? totalShares,
    int? currentStreak,
    int? bestStreak,
    int? xpPoints,
    int? level,
    Map<String, int>? questionsByCategory,
    Map<String, int>? sessionsByMode,
    DateTime? lastSessionDate,
    DateTime? firstSessionDate,
    List<String>? earnedBadgeIds,
    List<String>? earnedAchievementIds,
  }) {
    return UserStats(
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalSessions: totalSessions ?? this.totalSessions,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      totalShares: totalShares ?? this.totalShares,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
      questionsByCategory: questionsByCategory ?? this.questionsByCategory,
      sessionsByMode: sessionsByMode ?? this.sessionsByMode,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      firstSessionDate: firstSessionDate ?? this.firstSessionDate,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
      earnedAchievementIds: earnedAchievementIds ?? this.earnedAchievementIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalQuestionsAnswered': totalQuestionsAnswered,
    'totalSessions': totalSessions,
    'totalFavorites': totalFavorites,
    'totalShares': totalShares,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'xpPoints': xpPoints,
    'level': level,
    'questionsByCategory': questionsByCategory,
    'sessionsByMode': sessionsByMode,
    'lastSessionDate': lastSessionDate?.toIso8601String(),
    'firstSessionDate': firstSessionDate?.toIso8601String(),
    'earnedBadgeIds': earnedBadgeIds,
    'earnedAchievementIds': earnedAchievementIds,
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalQuestionsAnswered: json['totalQuestionsAnswered'] as int? ?? 0,
    totalSessions: json['totalSessions'] as int? ?? 0,
    totalFavorites: json['totalFavorites'] as int? ?? 0,
    totalShares: json['totalShares'] as int? ?? 0,
    currentStreak: json['currentStreak'] as int? ?? 0,
    bestStreak: json['bestStreak'] as int? ?? 0,
    xpPoints: json['xpPoints'] as int? ?? 0,
    level: json['level'] as int? ?? 1,
    questionsByCategory: Map<String, int>.from(json['questionsByCategory'] as Map? ?? {}),
    sessionsByMode: Map<String, int>.from(json['sessionsByMode'] as Map? ?? {}),
    lastSessionDate: json['lastSessionDate'] != null
        ? DateTime.parse(json['lastSessionDate'] as String)
        : null,
    firstSessionDate: json['firstSessionDate'] != null
        ? DateTime.parse(json['firstSessionDate'] as String)
        : null,
    earnedBadgeIds: List<String>.from(json['earnedBadgeIds'] as List? ?? []),
    earnedAchievementIds: List<String>.from(json['earnedAchievementIds'] as List? ?? []),
  );

  @override
  List<Object?> get props => [
    totalQuestionsAnswered, totalSessions, xpPoints, level,
    currentStreak, earnedBadgeIds,
  ];
}
