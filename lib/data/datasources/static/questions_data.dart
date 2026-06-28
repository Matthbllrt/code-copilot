import '../../../domain/models/question.dart';
import 'questions_romantic.dart';
import 'questions_hot.dart';
import 'questions_funny.dart';
import 'questions_deep.dart';
import 'questions_other.dart';

class QuestionsData {
  QuestionsData._();

  static List<Question> get allQuestions => [
    ...romanticQuestions,
    ...hotQuestions,
    ...funnyQuestions,
    ...deepQuestions,
    ...futureQuestions,
    ...randomQuestions,
    ...dateNightQuestions,
    ...communicationQuestions,
    ...truthOrDareQuestions,
  ];

  static List<Question> getByCategory(String categoryId) =>
      allQuestions.where((q) => q.categoryId == categoryId).toList();

  static Question? getById(String id) {
    try {
      return allQuestions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Question> getShuffled({String? categoryId, int? limit}) {
    final questions = categoryId != null
        ? getByCategory(categoryId)
        : List<Question>.from(allQuestions);
    questions.shuffle();
    if (limit != null && limit < questions.length) {
      return questions.take(limit).toList();
    }
    return questions;
  }

  static int get totalCount => allQuestions.length;
}
