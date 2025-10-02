import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
import '../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedUserType = "student"; // القيمة الافتراضية

  Future<void> _register() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      showAppMessage(context, "يرجى ملء جميع الحقول");
      return;
    }

    final newUser = User(
      username: _usernameController.text,
      password: _passwordController.text,
      userType: _selectedUserType,
    );

    final result = await DatabaseHelper.instance.registerUser(newUser);

    if (result != -1) {
      showAppMessage(context, "تم إنشاء الحساب بنجاح");
      Navigator.pop(context);
    } else {
      showAppMessage(context, "اسم المستخدم موجود مسبقاً");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إنشاء حساب")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(
              controller: _usernameController,
              label: "اسم المستخدم",
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: "كلمة المرور",
              isPassword: true,
              icon: Icons.lock,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedUserType,
              items: const [
                DropdownMenuItem(value: "student", child: Text("طالب")),
                DropdownMenuItem(value: "teacher", child: Text("أستاذ")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedUserType = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "نوع المستخدم",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "تسجيل",
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}
