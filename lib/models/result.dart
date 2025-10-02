class ExamResult {
  final int? id;
  final int examId;
  final int studentId;
  final int score;
  final int totalPoints;
  final DateTime completedAt;

  ExamResult({
    this.id,
    required this.examId,
    required this.studentId,
    required this.score,
    required this.totalPoints,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'studentId': studentId,
      'score': score,
      'totalPoints': totalPoints,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory ExamResult.fromMap(Map<String, dynamic> map) {
    return ExamResult(
      id: map['id'],
      examId: map['examId'],
      studentId: map['studentId'],
      score: map['score'],
      totalPoints: map['totalPoints'],
      completedAt: DateTime.parse(map['completedAt']),
    );
  }
}