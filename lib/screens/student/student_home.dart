import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_helper.dart';
import '../../models/exam.dart';
import '../../models/result.dart';
import '../login_screen.dart';
import 'take_exam.dart';
import 'exam_result_view.dart';

class StudentHome extends StatefulWidget {
  @override
  _StudentHomeState createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  List<Exam> _exams = [];
  List<ExamResult> _results = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final exams = await DatabaseHelper.instance.getExams();
    final results = await DatabaseHelper.instance.getResultsByStudent(
      AuthService.currentUser!.id!,
    );
    
    setState(() {
      _exams = exams;
      _results = results;
      _isLoading = false;
    });
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  bool _hasCompletedExam(int examId) {
    return _results.any((result) => result.examId == examId);
  }

  ExamResult? _getExamResult(int examId) {
    try {
      return _results.firstWhere((result) => result.examId == examId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم الطالب'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildExamsTab(),
                _buildResultsTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'الاختبارات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade),
            label: 'النتائج',
          ),
        ],
      ),
    );
  }

  Widget _buildExamsTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.person, size: 40, color: Colors.blue),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً ${AuthService.currentUser?.username}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('الاختبارات المتاحة: ${_exams.length}'),
                      Text('الاختبارات المكتملة: ${_results.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _exams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد اختبارات متاحة حالياً',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];
                    final isCompleted = _hasCompletedExam(exam.id!);
                    final result = _getExamResult(exam.id!);
                    
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCompleted ? Colors.green : Colors.blue,
                          child: Icon(
                            isCompleted ? Icons.check : Icons.quiz,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(exam.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('المادة: ${exam.subject}'),
                            Text('الوقت: ${exam.timeLimit} دقيقة'),
                            if (isCompleted && result != null)
                              Text(
                                'النتيجة: ${result.score}/${result.totalPoints}',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(
                          isCompleted ? Icons.visibility : Icons.play_arrow,
                          color: isCompleted ? Colors.green : Colors.blue,
                        ),
                        onTap: () async {
                          if (isCompleted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExamResultView(
                                  exam: exam,
                                  result: result!,
                                ),
                              ),
                            );
                          } else {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TakeExamScreen(exam: exam),
                              ),
                            );
                            _loadData(); // Refresh data after taking exam
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResultsTab() {
    return _results.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grade,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'لا توجد نتائج حتى الآن',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final result = _results[index];
              final exam = _exams.firstWhere((e) => e.id == result.examId);
              final percentage = (result.score / result.totalPoints * 100).round();
              
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getGradeColor(percentage),
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(exam.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المادة: ${exam.subject}'),
                      Text('النتيجة: ${result.score}/${result.totalPoints}'),
                      Text(
                        'تاريخ الإكمال: ${_formatDate(result.completedAt)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamResultView(
                          exam: exam,
                          result: result,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
    return '${date.day}/${date.month}/${date.year}';
  }
}