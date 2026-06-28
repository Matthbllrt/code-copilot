import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/game_session.dart';
import '../../../domain/models/question.dart';
import '../../../domain/repositories/question_repository.dart';
import '../../home/providers/home_provider.dart';
import '../../../core/constants/app_constants.dart';

const _uuid = Uuid();

class GameSessionNotifier extends Notifier<GameSession?> {
  @override
  GameSession? build() => null;

  void startSession({
    required GameMode mode,
    required List<String> categoryIds,
    int? questionCount,
    DifficultyLevel? difficulty,
  }) {
    final repo = ref.read(questionRepositoryProvider);
    List<Question> questions = [];

    if (categoryIds.isEmpty) {
      questions = repo.getShuffled(
        limit: questionCount ?? AppConstants.cardsPerSession,
      );
    } else {
      for (final catId in categoryIds) {
        final catQuestions = repo.getFiltered(
          categoryId: catId,
          difficulty: difficulty,
        );
        questions.addAll(catQuestions);
      }
      questions.shuffle();
      final limit = questionCount ?? AppConstants.cardsPerSession;
      if (questions.length > limit) {
        questions = questions.take(limit).toList();
      }
    }

    state = GameSession(
      id: _uuid.v4(),
      mode: mode,
      categoryIds: categoryIds,
      questions: questions,
      startedAt: DateTime.now(),
    );
  }

  void nextQuestion() {
    final session = state;
    if (session == null) return;
    if (session.currentQuestion != null) {
      final answered = [...session.answeredQuestionIds, session.currentQuestion!.id];
      state = session.copyWith(
        currentIndex: session.currentIndex + 1,
        answeredQuestionIds: answered,
      );
      ref.read(userStatsProvider.notifier).recordQuestion(
        session.currentQuestion?.categoryId ?? '',
      );
    }
  }

  void skipQuestion() {
    final session = state;
    if (session == null) return;
    if (session.currentQuestion != null) {
      final skipped = [...session.skippedQuestionIds, session.currentQuestion!.id];
      state = session.copyWith(
        currentIndex: session.currentIndex + 1,
        skippedQuestionIds: skipped,
      );
    }
  }

  void addDuelScore(int player) {
    final session = state;
    if (session == null) return;
    if (player == 1) {
      state = session.copyWith(duelPlayer1Score: session.duelPlayer1Score + 1);
    } else {
      state = session.copyWith(duelPlayer2Score: session.duelPlayer2Score + 1);
    }
  }

  void completeSession() {
    final session = state;
    if (session == null) return;
    state = session.copyWith(
      status: SessionStatus.completed,
      endedAt: DateTime.now(),
    );
    ref.read(userStatsProvider.notifier).recordSession(session.mode.name);
  }

  void abandonSession() {
    final session = state;
    if (session == null) return;
    state = session.copyWith(
      status: SessionStatus.abandoned,
      endedAt: DateTime.now(),
    );
  }

  void resetSession() {
    state = null;
  }

  // Infinite mode — add more questions when running low
  void addMoreQuestions() {
    final session = state;
    if (session == null) return;
    final repo = ref.read(questionRepositoryProvider);
    final usedIds = [
      ...session.answeredQuestionIds,
      ...session.skippedQuestionIds,
    ];
    final newQuestions = repo.getFiltered(
      excludeIds: usedIds,
    )..shuffle();
    state = session.copyWith(
      questions: [...session.questions, ...newQuestions.take(10)],
    );
  }
}

final gameSessionProvider = NotifierProvider<GameSessionNotifier, GameSession?>(
  GameSessionNotifier.new,
);

// Quick random question provider
final randomQuestionProvider = Provider.family<Question?, String?>((ref, categoryId) {
  final repo = ref.read(questionRepositoryProvider);
  final questions = repo.getShuffled(categoryId: categoryId, limit: 1);
  return questions.isEmpty ? null : questions.first;
});
