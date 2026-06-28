import 'package:equatable/equatable.dart';

class HistoryEntry extends Equatable {
  final String id;
  final String questionId;
  final String questionText;
  final String categoryId;
  final DateTime viewedAt;
  final bool wasFavorited;

  const HistoryEntry({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.categoryId,
    required this.viewedAt,
    this.wasFavorited = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionId': questionId,
    'questionText': questionText,
    'categoryId': categoryId,
    'viewedAt': viewedAt.toIso8601String(),
    'wasFavorited': wasFavorited,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String,
    questionId: json['questionId'] as String,
    questionText: json['questionText'] as String,
    categoryId: json['categoryId'] as String,
    viewedAt: DateTime.parse(json['viewedAt'] as String),
    wasFavorited: json['wasFavorited'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, questionId, viewedAt];
}
