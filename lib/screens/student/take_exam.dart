import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/auth_service.dart';
import '../../models/exam.dart';
import '../../models/question.dart';
import '../../models/result.dart';

class TakeExamScreen extends StatefulWidget {
  final Exam exam;

  TakeExamScreen({required this.exam});

  @override
  _TakeExamScreenState createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  List<Question> _questions = [];
  Map<int, String> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  Timer? _timer;
  int _remainingTime = 0;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final questions = await DatabaseHelper.instance.getQuestionsByExam(widget.exam.id!);
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  void _startTimer() {
    _remainingTime = widget.exam.timeLimit * 60; // Convert to seconds
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _submitExam(); // Auto-submit when time is up
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitExam() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();

    int totalScore = 0;
    int totalPoints = 0;

    for (var question in _questions) {
      totalPoints += question.points;
      final userAnswer = _answers[question.id];
      
      if (userAnswer != null) {
        if (question.questionType == 'essay') {
          // For essay questions, use simple similarity check
          // In a real app, you would use AI API here
          final similarity = _calculateSimilarity(userAnswer, question.correctAnswer);
          if (similarity > 0.6) { // 60% similarity threshold
            totalScore += question.points;
          }
        } else {
          // For multiple choice and true/false
          if (userAnswer == question.correctAnswer) {
            totalScore += question.points;
          }
        }
      }
    }

    final result = ExamResult(
      examId: widget.exam.id!,
      studentId: AuthService.currentUser!.id!,
      score: totalScore,
      totalPoints: totalPoints,
      completedAt: DateTime.now(),
    );

    await DatabaseHelper.instance.saveResult(result);

    setState(() {
      _isSubmitting = false;
    });

    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('انتهى الاختبار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'النتيجة: $totalScore من $totalPoints',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'النسبة: ${(totalScore / totalPoints * 100).round()}%',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to student home
            },
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  double _calculateSimilarity(String answer1, String answer2) {
    // Simple similarity calculation (word matching)
    final words1 = answer1.toLowerCase().split(' ');
    final words2 = answer2.toLowerCase().split(' ');
    
    int matchCount = 0;
    for (String word in words1) {
      if (words2.contains(word) && word.length > 2) {
        matchCount++;
      }
    }
    
    return matchCount / words2.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.exam.title)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.exam.title)),
        body: Center(
          child: Text(
            'لا توجد أسئلة في هذا الاختبار',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('تأكيد الخروج'),
            content: Text('هل أنت متأكد من الخروج؟ سيتم فقدان إجاباتك.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('خروج'),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.exam.title),
          backgroundColor: _remainingTime < 300 ? Colors.red : Colors.blue, // Red when < 5 minutes
          actions: [
            Container(
              padding: EdgeInsets.all(8),
              child: Center(
                child: Text(
                  _formatTime(_remainingTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('السؤال ${_currentQuestionIndex + 1} من ${_questions.length}'),
                      Text('النقاط: ${currentQuestion.points}'),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _questions.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentQuestion.questionText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildAnswerOptions(currentQuestion),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: Text('السابق'),
                    )
                  else
                    SizedBox(),
                  if (_currentQuestionIndex < _questions.length - 1)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex++;
                        });
                      },
                      child: Text('التالي'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitExam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isSubmitting
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('إنهاء الاختبار'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(Question question) {
    switch (question.questionType) {
      case 'multiple_choice':
        return Column(
          children: question.options!.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final optionValue = (index + 1).toString();
            
            return RadioListTile<String>(
              title: Text(option),
              value: optionValue,
              groupValue: _answers[question.id],
              onChanged: (value) {
                setState(() {
                  _answers[question.id!] = value!;
                });
              },
            );
          }).toList(),
        );
        
      case 'true_false':
        return Column(
          children: [
            RadioListTile<String>(
              title: Text('صح'),
              value: 'true',
              groupValue: _answers[question.id],
              onChanged: (value) {
                setState(() {
                  _answers[question.id!] = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('خطأ'),
              value: 'false',
              groupValue: _answers[question.id],
              onChanged: (value) {
                setState(() {
                  _answers[question.id!] = value!;
                });
              },
            ),
          ],
        );
        
      case 'essay':
        return TextField(
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'اكتب إجابتك هنا...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _answers[question.id!] = value;
          },
        );
        
      default:
        return Text('نوع سؤال غير مدعوم');
    }
  }
}