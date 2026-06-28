import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum BadgeRarity { common, rare, epic, legendary }

extension BadgeRarityExtension on BadgeRarity {
  String get label {
    switch (this) {
      case BadgeRarity.common: return 'Commun';
      case BadgeRarity.rare: return 'Rare';
      case BadgeRarity.epic: return 'Épique';
      case BadgeRarity.legendary: return 'Légendaire';
    }
  }

  Color get color {
    switch (this) {
      case BadgeRarity.common: return const Color(0xFF9E9E9E);
      case BadgeRarity.rare: return const Color(0xFF2196F3);
      case BadgeRarity.epic: return const Color(0xFF9B5DE5);
      case BadgeRarity.legendary: return const Color(0xFFFFB347);
    }
  }

  List<Color> get gradient {
    switch (this) {
      case BadgeRarity.common: return [const Color(0xFF9E9E9E), const Color(0xFF757575)];
      case BadgeRarity.rare: return [const Color(0xFF2196F3), const Color(0xFF0D47A1)];
      case BadgeRarity.epic: return [const Color(0xFF9B5DE5), const Color(0xFF6A0DAD)];
      case BadgeRarity.legendary: return [const Color(0xFFFFB347), const Color(0xFFFF6B35)];
    }
  }
}

class BadgeModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeRarity rarity;
  final String condition;
  final bool isEarned;
  final DateTime? earnedAt;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.rarity,
    required this.condition,
    this.isEarned = false,
    this.earnedAt,
  });

  BadgeModel copyWith({
    bool? isEarned,
    DateTime? earnedAt,
  }) {
    return BadgeModel(
      id: id,
      name: name,
      description: description,
      emoji: emoji,
      rarity: rarity,
      condition: condition,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  static List<BadgeModel> get allBadges => [
    const BadgeModel(
      id: 'first_question',
      name: 'Premier Pas',
      description: 'Répondez à votre première question',
      emoji: '🌱',
      rarity: BadgeRarity.common,
      condition: 'totalQuestionsAnswered >= 1',
    ),
    const BadgeModel(
      id: 'ten_questions',
      name: 'Explorateurs',
      description: 'Répondez à 10 questions',
      emoji: '🗺️',
      rarity: BadgeRarity.common,
      condition: 'totalQuestionsAnswered >= 10',
    ),
    const BadgeModel(
      id: 'fifty_questions',
      name: 'Curieux',
      description: 'Répondez à 50 questions',
      emoji: '🔍',
      rarity: BadgeRarity.common,
      condition: 'totalQuestionsAnswered >= 50',
    ),
    const BadgeModel(
      id: 'hundred_questions',
      name: 'Centurion',
      description: 'Répondez à 100 questions',
      emoji: '💯',
      rarity: BadgeRarity.rare,
      condition: 'totalQuestionsAnswered >= 100',
    ),
    const BadgeModel(
      id: 'five_hundred_questions',
      name: 'Passionné',
      description: 'Répondez à 500 questions',
      emoji: '🔥',
      rarity: BadgeRarity.epic,
      condition: 'totalQuestionsAnswered >= 500',
    ),
    const BadgeModel(
      id: 'thousand_questions',
      name: 'Légende',
      description: 'Répondez à 1000 questions',
      emoji: '👑',
      rarity: BadgeRarity.legendary,
      condition: 'totalQuestionsAnswered >= 1000',
    ),
    const BadgeModel(
      id: 'first_session',
      name: 'C\'est parti !',
      description: 'Complétez votre première session',
      emoji: '🎉',
      rarity: BadgeRarity.common,
      condition: 'totalSessions >= 1',
    ),
    const BadgeModel(
      id: 'ten_sessions',
      name: 'Habitués',
      description: 'Complétez 10 sessions',
      emoji: '🎯',
      rarity: BadgeRarity.rare,
      condition: 'totalSessions >= 10',
    ),
    const BadgeModel(
      id: 'fifty_sessions',
      name: 'Dévoués',
      description: 'Complétez 50 sessions',
      emoji: '💎',
      rarity: BadgeRarity.epic,
      condition: 'totalSessions >= 50',
    ),
    const BadgeModel(
      id: 'streak_3',
      name: 'En Série',
      description: '3 jours consécutifs de jeu',
      emoji: '⚡',
      rarity: BadgeRarity.common,
      condition: 'currentStreak >= 3',
    ),
    const BadgeModel(
      id: 'streak_7',
      name: 'Une Semaine',
      description: '7 jours consécutifs de jeu',
      emoji: '📅',
      rarity: BadgeRarity.rare,
      condition: 'currentStreak >= 7',
    ),
    const BadgeModel(
      id: 'streak_30',
      name: 'Un Mois',
      description: '30 jours consécutifs de jeu',
      emoji: '🏆',
      rarity: BadgeRarity.epic,
      condition: 'currentStreak >= 30',
    ),
    const BadgeModel(
      id: 'first_favorite',
      name: 'Coup de Cœur',
      description: 'Ajoutez votre première question en favori',
      emoji: '❤️',
      rarity: BadgeRarity.common,
      condition: 'totalFavorites >= 1',
    ),
    const BadgeModel(
      id: 'twenty_favorites',
      name: 'Collectionneur',
      description: 'Ajoutez 20 questions en favoris',
      emoji: '💝',
      rarity: BadgeRarity.rare,
      condition: 'totalFavorites >= 20',
    ),
    const BadgeModel(
      id: 'first_share',
      name: 'Partageons !',
      description: 'Partagez votre première question',
      emoji: '📤',
      rarity: BadgeRarity.common,
      condition: 'totalShares >= 1',
    ),
    const BadgeModel(
      id: 'night_owl',
      name: 'Oiseaux de Nuit',
      description: 'Jouez après 22h',
      emoji: '🌙',
      rarity: BadgeRarity.rare,
      condition: 'night_session',
    ),
    const BadgeModel(
      id: 'all_categories',
      name: 'Touche-à-Tout',
      description: 'Explorez toutes les catégories',
      emoji: '🌈',
      rarity: BadgeRarity.epic,
      condition: 'all_categories_explored',
    ),
    const BadgeModel(
      id: 'level_5',
      name: 'Complices',
      description: 'Atteignez le niveau 5',
      emoji: '⭐',
      rarity: BadgeRarity.rare,
      condition: 'level >= 5',
    ),
    const BadgeModel(
      id: 'level_10',
      name: 'Âmes Sœurs',
      description: 'Atteignez le niveau 10',
      emoji: '💫',
      rarity: BadgeRarity.legendary,
      condition: 'level >= 10',
    ),
  ];

  @override
  List<Object?> get props => [id, isEarned, earnedAt];
}
