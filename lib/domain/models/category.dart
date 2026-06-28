import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class QuestionCategory extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final LinearGradient gradient;
  final Color color;
  final int questionCount;
  final bool isLocked;

  const QuestionCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.gradient,
    required this.color,
    required this.questionCount,
    this.isLocked = false,
  });

  static List<QuestionCategory> get allCategories => [
    const QuestionCategory(
      id: AppConstants.catRomantic,
      name: 'Romantique',
      emoji: '❤️',
      description: 'Des questions pour raviver la flamme et explorer votre amour',
      gradient: AppColors.romanticGradient,
      color: AppColors.primary,
      questionCount: 200,
    ),
    const QuestionCategory(
      id: AppConstants.catHot,
      name: 'Questions Chaudes',
      emoji: '🔥',
      description: 'Suggestif, ludique et consenti — pimentez votre relation',
      gradient: AppColors.hotGradient,
      color: AppColors.secondary,
      questionCount: 150,
    ),
    const QuestionCategory(
      id: AppConstants.catFunny,
      name: 'Drôle',
      emoji: '😂',
      description: 'Rires garantis — découvrez votre côté décalé en couple',
      gradient: AppColors.funnyGradient,
      color: AppColors.accent,
      questionCount: 200,
    ),
    const QuestionCategory(
      id: AppConstants.catDeep,
      name: 'Profond',
      emoji: '🧠',
      description: 'Plongez dans les profondeurs de vos pensées et émotions',
      gradient: AppColors.deepGradient,
      color: AppColors.accentPurple,
      questionCount: 175,
    ),
    const QuestionCategory(
      id: AppConstants.catFuture,
      name: 'Futur',
      emoji: '💍',
      description: 'Construisez votre avenir ensemble, question par question',
      gradient: AppColors.futureGradient,
      color: AppColors.accentBlue,
      questionCount: 150,
    ),
    const QuestionCategory(
      id: AppConstants.catRandom,
      name: 'Aléatoire',
      emoji: '🎲',
      description: 'Surprises et découvertes — laissez le hasard décider',
      gradient: AppColors.randomGradient,
      color: AppColors.accentGreen,
      questionCount: 300,
    ),
    const QuestionCategory(
      id: AppConstants.catDateNight,
      name: 'Date Night',
      emoji: '🥂',
      description: 'Transformez chaque soirée en une nuit inoubliable',
      gradient: AppColors.dateNightGradient,
      color: Color(0xFF9B5DE5),
      questionCount: 150,
    ),
    const QuestionCategory(
      id: AppConstants.catCommunication,
      name: 'Communication',
      emoji: '💬',
      description: 'Renforcez votre connexion et votre compréhension mutuelle',
      gradient: AppColors.communicationGradient,
      color: AppColors.accentBlue,
      questionCount: 175,
    ),
    const QuestionCategory(
      id: AppConstants.catTruthOrDare,
      name: 'Action ou Vérité',
      emoji: '❓',
      description: 'Le jeu classique revisité pour les couples — osez tout !',
      gradient: AppColors.truthOrDareGradient,
      color: Color(0xFFFC466B),
      questionCount: 200,
    ),
  ];

  @override
  List<Object?> get props => [id, name, emoji, questionCount, isLocked];
}
