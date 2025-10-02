import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/auth_service.dart';
import '../../models/exam.dart';
import '../../models/question.dart';

class CreateExamScreen extends StatefulWidget {
  @override
  _CreateExamScreenState createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _timeLimitController = TextEditingController();
  
  List<Question> _questions = [];
  bool _isLoading = false;

  Future<void> _createExam() async {
    if (_titleController.text.isEmpty || 
        _subjectController.text.isEmpty || 
        _timeLimitController.text.isEmpty ||
        _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى ملء جميع الحقول وإضافة سؤال واحد على الأقل')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final exam = Exam(
        title: _titleController.text,
        subject: _subjectController.text,
        teacherId: AuthService.currentUser!.id!,
        timeLimit: int.parse(_timeLimitController.text),
        createdAt: DateTime.now(),
      );

      final examId = await DatabaseHelper.instance.createExam(exam);

      for (var question in _questions) {
        final questionWithExamId = Question(
          examId: examId,
          questionText: question.questionText,
          questionType: question.questionType,
          options: question.options,
          correctAnswer: question.correctAnswer,
          points: question.points,
        );
        await DatabaseHelper.instance.createQuestion(questionWithExamId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء الاختبار بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء الاختبار')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => AddQuestionDialog(
        onQuestionAdded: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إنشاء اختبار جديد'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _createExam,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'معلومات الاختبار',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'عنوان الاختبار',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              labelText: 'المادة',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _timeLimitController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'مدة الاختبار (بالدقائق)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأسئلة (${_questions.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: Icon(Icons.add),
                        label: Text('إضافة سؤال'),
                      ),
                    ],
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
                        child: ListTile(
                          title: Text(
                            'السؤال ${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(question.questionText),
                              SizedBox(height: 4),
                              Text(
                                'النوع: ${_getQuestionTypeText(question.questionType)} | النقاط: ${question.points}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _questions.removeAt(index);
                              });
                            },
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

  String _getQuestionTypeText(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'اختيار من متعدد';
      case 'true_false':
        return 'صح/خطأ';
      case 'essay':
        return 'مقالي';
      default:
        return type;
    }
  }
}

class AddQuestionDialog extends StatefulWidget {
  final Function(Question) onQuestionAdded;

  AddQuestionDialog({required this.onQuestionAdded});

  @override
  _AddQuestionDialogState createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _questionController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  final _essayAnswerController = TextEditingController();
  
  String _selectedType = 'multiple_choice';
  String _correctAnswer = '';
  String _trueFalseAnswer = 'true';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة سؤال جديد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'نص السؤال',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'نوع السؤال',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'multiple_choice',
                          child: Text('اختيار من متعدد'),
                        ),
                        DropdownMenuItem(
                          value: 'true_false',
                          child: Text('صح/خطأ'),
                        ),
                        DropdownMenuItem(
                          value: 'essay',
                          child: Text('مقالي'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          _correctAnswer = '';
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'النقاط',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildQuestionTypeFields(),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إلغاء'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addQuestion,
                    child: Text('إضافة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTypeFields() {
    switch (_selectedType) {
      case 'multiple_choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الخيارات:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildOptionField(_option1Controller, 'الخيار 1', '1'),
            _buildOptionField(_option2Controller, 'الخيار 2', '2'),
            _buildOptionField(_option3Controller, 'الخيار 3', '3'),
            _buildOptionField(_option4Controller, 'الخيار 4', '4'),
            SizedBox(height: 8),
            Text('الإجابة الصحيحة:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _correctAnswer.isEmpty ? null : _correctAnswer,
              hint: Text('اختر الإجابة الصحيحة'),
              isExpanded: true,
              items: ['1', '2', '3', '4'].map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text('الخيار $option'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _correctAnswer = value!;
                });
              },
            ),
          ],
        );
      case 'true_false':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإجابة الصحيحة:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: Text('صح'),
              value: 'true',
              groupValue: _trueFalseAnswer,
              onChanged: (value) {
                setState(() {
                  _trueFalseAnswer = value!;
                  _correctAnswer = value;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('خطأ'),
              value: 'false',
              groupValue: _trueFalseAnswer,
              onChanged: (value) {
                setState(() {
                  _trueFalseAnswer = value!;
                  _correctAnswer = value;
                });
              },
            ),
          ],
        );
      case 'essay':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإجابة النموذجية:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: _essayAnswerController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'اكتب الإجابة النموذجية للسؤال المقالي',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _correctAnswer = value;
              },
            ),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _buildOptionField(TextEditingController controller, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void _addQuestion() {
    if (_questionController.text.isEmpty || _pointsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    List<String>? options;
    if (_selectedType == 'multiple_choice') {
      if (_option1Controller.text.isEmpty || 
          _option2Controller.text.isEmpty ||
          _correctAnswer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يرجى ملء خيارين على الأقل واختيار الإجابة الصحيحة')),
        );
        return;
      }
      options = [
        _option1Controller.text,
        _option2Controller.text,
        _option3Controller.text,
        _option4Controller.text,
      ].where((option) => option.isNotEmpty).toList();
    }

    if (_selectedType == 'essay' && _correctAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى كتابة الإجابة النموذجية للسؤال المقالي')),
      );
      return;
    }

    final question = Question(
      examId: 0, // Will be set when saving
      questionText: _questionController.text,
      questionType: _selectedType,
      options: options,
      correctAnswer: _correctAnswer,
      points: int.parse(_pointsController.text),
    );

    widget.onQuestionAdded(question);
    Navigator.pop(context);
  }
}