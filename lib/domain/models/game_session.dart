import 'package:equatable/equatable.dart';
import 'question.dart';

enum GameMode {
  classic,
  infinite,
  duel,
  challenge,
  random,
  date,
  evening,
  custom,
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.classic: return 'Classique';
      case GameMode.infinite: return 'Infini';
      case GameMode.duel: return 'Duel';
      case GameMode.challenge: return 'Défis';
      case GameMode.random: return 'Aléatoire';
      case GameMode.date: return 'Date Night';
      case GameMode.evening: return 'Soirée';
      case GameMode.custom: return 'Personnalisé';
    }
  }

  String get emoji {
    switch (this) {
      case GameMode.classic: return '🃏';
      case GameMode.infinite: return '♾️';
      case GameMode.duel: return '⚔️';
      case GameMode.challenge: return '🏆';
      case GameMode.random: return '🎲';
      case GameMode.date: return '🥂';
      case GameMode.evening: return '🌙';
      case GameMode.custom: return '✨';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic: return '20 questions choisies pour vous';
      case GameMode.infinite: return 'Questions sans limite jusqu\'à ce que vous décidiez d\'arrêter';
      case GameMode.duel: return 'Chacun répond — comparez vos réponses';
      case GameMode.challenge: return 'Des défis à accomplir ensemble';
      case GameMode.random: return 'Pioche une question au hasard';
      case GameMode.date: return 'Questions parfaites pour une soirée en tête-à-tête';
      case GameMode.evening: return 'Mode soirée pour les grandes occasions';
      case GameMode.custom: return 'Créez votre session sur mesure';
    }
  }
}

enum SessionStatus { active, paused, completed, abandoned }

class GameSession extends Equatable {
  final String id;
  final GameMode mode;
  final List<String> categoryIds;
  final List<Question> questions;
  final int currentIndex;
  final List<String> answeredQuestionIds;
  final List<String> skippedQuestionIds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final int score;
  final int duelPlayer1Score;
  final int duelPlayer2Score;

  const GameSession({
    required this.id,
    required this.mode,
    required this.categoryIds,
    required this.questions,
    this.currentIndex = 0,
    this.answeredQuestionIds = const [],
    this.skippedQuestionIds = const [],
    required this.startedAt,
    this.endedAt,
    this.status = SessionStatus.active,
    this.score = 0,
    this.duelPlayer1Score = 0,
    this.duelPlayer2Score = 0,
  });

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isCompleted => currentIndex >= questions.length;

  double get progress =>
      questions.isEmpty ? 0 : currentIndex / questions.length;

  int get remainingQuestions => questions.length - currentIndex;

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  GameSession copyWith({
    String? id,
    GameMode? mode,
    List<String>? categoryIds,
    List<Question>? questions,
    int? currentIndex,
    List<String>? answeredQuestionIds,
    List<String>? skippedQuestionIds,
    DateTime? startedAt,
    DateTime? endedAt,
    SessionStatus? status,
    int? score,
    int? duelPlayer1Score,
    int? duelPlayer2Score,
  }) {
    return GameSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      categoryIds: categoryIds ?? this.categoryIds,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
      skippedQuestionIds: skippedQuestionIds ?? this.skippedQuestionIds,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      score: score ?? this.score,
      duelPlayer1Score: duelPlayer1Score ?? this.duelPlayer1Score,
      duelPlayer2Score: duelPlayer2Score ?? this.duelPlayer2Score,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mode': mode.name,
    'categoryIds': categoryIds,
    'currentIndex': currentIndex,
    'answeredQuestionIds': answeredQuestionIds,
    'skippedQuestionIds': skippedQuestionIds,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'status': status.name,
    'score': score,
  };

  @override
  List<Object?> get props => [id, mode, currentIndex, status, score];
}
