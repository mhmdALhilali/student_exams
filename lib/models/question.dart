class Question {
  final int? id;
  final int examId;
  final String questionText;
  final String questionType; // 'multiple_choice', 'true_false', 'essay'
  final List<String>? options; // For multiple choice
  final String correctAnswer;
  final int points;

  Question({
    this.id,
    required this.examId,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.correctAnswer,
    required this.points,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'questionText': questionText,
      'questionType': questionType,
      'options': options?.join('|'), // Store as pipe-separated string
      'correctAnswer': correctAnswer,
      'points': points,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      examId: map['examId'],
      questionText: map['questionText'],
      questionType: map['questionType'],
      options: map['options']?.split('|'),
      correctAnswer: map['correctAnswer'],
      points: map['points'],
    );
  }
}