import '../../domain/models/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/static/questions_data.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  const QuestionRepositoryImpl();

  @override
  List<Question> getAllQuestions() => QuestionsData.allQuestions;

  @override
  List<Question> getByCategory(String categoryId) =>
      QuestionsData.getByCategory(categoryId);

  @override
  Question? getById(String id) => QuestionsData.getById(id);

  @override
  List<Question> getShuffled({String? categoryId, int? limit}) =>
      QuestionsData.getShuffled(categoryId: categoryId, limit: limit);

  @override
  List<Question> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    return QuestionsData.allQuestions
        .where((question) =>
            question.text.toLowerCase().contains(q) ||
            question.tags.any((tag) => tag.toLowerCase().contains(q)))
        .toList();
  }

  @override
  List<Question> getFiltered({
    String? categoryId,
    DifficultyLevel? difficulty,
    QuestionType? type,
    List<String>? excludeIds,
  }) {
    return QuestionsData.allQuestions.where((q) {
      if (categoryId != null && q.categoryId != categoryId) return false;
      if (difficulty != null && q.difficulty != difficulty) return false;
      if (type != null && q.type != type) return false;
      if (excludeIds != null && excludeIds.contains(q.id)) return false;
      return true;
    }).toList();
  }

  @override
  int getTotalCount() => QuestionsData.totalCount;

  @override
  int getCountByCategory(String categoryId) =>
      QuestionsData.getByCategory(categoryId).length;
}
