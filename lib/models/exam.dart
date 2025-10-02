class Exam {
  final int? id;
  final String title;
  final String subject;
  final int teacherId;
  final int timeLimit; // in minutes
  final DateTime createdAt;

  Exam({
    this.id,
    required this.title,
    required this.subject,
    required this.teacherId,
    required this.timeLimit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'teacherId': teacherId,
      'timeLimit': timeLimit,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      teacherId: map['teacherId'],
      timeLimit: map['timeLimit'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}