import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'teacher/teacher_home.dart';
import 'student/student_home.dart';
import 'register_screen.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      showAppMessage(context, 'يرجى إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() => _isLoading = true);

    final user = await DatabaseHelper.instance.loginUser(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      AuthService.setCurrentUser(user);

      if (user.userType == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TeacherHome()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentHome()),
        );
      }
    } else {
      showAppMessage(context, 'اسم المستخدم أو كلمة المرور غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 250, 245, 245)!,
              const Color.fromARGB(255, 255, 255, 255)!,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school,
                      size: 80,
                      color: const Color.fromARGB(255, 74, 115, 110),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'نظام إدارة الاختبارات',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 80, 151, 141),
                      ),
                    ),
                    SizedBox(height: 32),

                    CustomTextField(
                      controller: _usernameController,
                      label: "اسم المستخدم",
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: "كلمة المرور",
                      isPassword: true,
                    ),

                    SizedBox(height: 24),

                    CustomButton(
                      text: _isLoading
                          ? "جارٍ تسجيل الدخول..."
                          : "تسجيل الدخول",
                      onPressed: _isLoading ? () {} : _login,
                    ),

                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "إنشاء حساب جديد",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 238, 89, 31),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'الحسابات التجريبية:\nأستاذ: teacher1 / 123456\nطالب: student1 / 123456',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
