import 'package:equatable/equatable.dart';

enum QuestionType { classic, truthOrDare, challenge }

enum DifficultyLevel { easy, medium, hard, spicy }

class Question extends Equatable {
  final String id;
  final String text;
  final String categoryId;
  final QuestionType type;
  final DifficultyLevel difficulty;
  final List<String> tags;
  final bool isCustom;
  final DateTime? createdAt;

  const Question({
    required this.id,
    required this.text,
    required this.categoryId,
    this.type = QuestionType.classic,
    this.difficulty = DifficultyLevel.easy,
    this.tags = const [],
    this.isCustom = false,
    this.createdAt,
  });

  Question copyWith({
    String? id,
    String? text,
    String? categoryId,
    QuestionType? type,
    DifficultyLevel? difficulty,
    List<String>? tags,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'categoryId': categoryId,
    'type': type.name,
    'difficulty': difficulty.name,
    'tags': tags,
    'isCustom': isCustom,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    text: json['text'] as String,
    categoryId: json['categoryId'] as String,
    type: QuestionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => QuestionType.classic,
    ),
    difficulty: DifficultyLevel.values.firstWhere(
      (e) => e.name == json['difficulty'],
      orElse: () => DifficultyLevel.easy,
    ),
    tags: List<String>.from(json['tags'] as List? ?? []),
    isCustom: json['isCustom'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );

  @override
  List<Object?> get props => [id, text, categoryId, type, difficulty, tags, isCustom];
}
