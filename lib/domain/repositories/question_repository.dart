import '../models/question.dart';

abstract interface class QuestionRepository {
  List<Question> getAllQuestions();
  List<Question> getByCategory(String categoryId);
  Question? getById(String id);
  List<Question> getShuffled({String? categoryId, int? limit});
  List<Question> search(String query);
  List<Question> getFiltered({
    String? categoryId,
    DifficultyLevel? difficulty,
    QuestionType? type,
    List<String>? excludeIds,
  });
  int getTotalCount();
  int getCountByCategory(String categoryId);
}
