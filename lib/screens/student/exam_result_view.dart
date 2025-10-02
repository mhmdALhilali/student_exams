import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/exam.dart';
import '../../models/question.dart';
import '../../models/result.dart';

class ExamResultView extends StatefulWidget {
  final Exam exam;
  final ExamResult result;

  ExamResultView({required this.exam, required this.result});

  @override
  _ExamResultViewState createState() => _ExamResultViewState();
}

class _ExamResultViewState extends State<ExamResultView> {
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await DatabaseHelper.instance.getQuestionsByExam(widget.exam.id!);
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.result.score / widget.result.totalPoints * 100).round();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('نتيجة الاختبار'),
        backgroundColor: _getGradeColor(percentage),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            widget.exam.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'المادة: ${widget.exam.subject}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'النتيجة',
                                '${widget.result.score}/${widget.result.totalPoints}',
                                Colors.blue,
                              ),
                              _buildStatCard(
                                'النسبة المئوية',
                                '$percentage%',
                                _getGradeColor(percentage),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildGradeIndicator(percentage),
                          SizedBox(height: 8),
                          Text(
                            'تاريخ الإكمال: ${_formatDate(widget.result.completedAt)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'مراجعة الأسئلة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'السؤال ${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    '${question.points} نقاط',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                question.questionText,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 12),
                              _buildQuestionReview(question),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeIndicator(int percentage) {
    String grade;
    Color color = _getGradeColor(percentage);
    
    if (percentage >= 90) grade = 'ممتاز';
    else if (percentage >= 80) grade = 'جيد جداً';
    else if (percentage >= 70) grade = 'جيد';
    else if (percentage >= 60) grade = 'مقبول';
    else grade = 'راسب';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuestionReview(Question question) {
    switch (question.questionType) {
      case 'multiple_choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...question.options!.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionValue = (index + 1).toString();
              final isCorrect = optionValue == question.correctAnswer;
              
              return Container(
                margin: EdgeInsets.only(bottom: 4),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.withOpacity(0.1) : null,
                  border: isCorrect ? Border.all(color: Colors.green) : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text('${String.fromCharCode(65 + index)}. '),
                    Expanded(child: Text(option)),
                    if (isCorrect)
                      Icon(Icons.check, color: Colors.green, size: 16),
                  ],
                ),
              );
            }).toList(),
          ],
        );
        
      case 'true_false':
        return Column(
          children: [
            _buildTrueFalseOption('صح', 'true', question.correctAnswer == 'true'),
            _buildTrueFalseOption('خطأ', 'false', question.correctAnswer == 'false'),
          ],
        );
        
      case 'essay':
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإجابة النموذجية:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text(question.correctAnswer),
            ],
          ),
        );
        
      default:
        return Container();
    }
  }

  Widget _buildTrueFalseOption(String text, String value, bool isCorrect) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.1) : null,
        border: isCorrect ? Border.all(color: Colors.green) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text)),
          if (isCorrect)
            Icon(Icons.check, color: Colors.green, size: 16),
        ],
      ),
    );
  }

  Color _getGradeColor(int percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}