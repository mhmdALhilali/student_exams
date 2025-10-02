import '../models/user.dart';

class AuthService {
  static User? _currentUser;

  static User? get currentUser => _currentUser;

  static void setCurrentUser(User user) {
    _currentUser = user;
  }

  static void logout() {
    _currentUser = null;
  }

  static bool isTeacher() {
    return _currentUser?.userType == 'teacher';
  }

  static bool isStudent() {
    return _currentUser?.userType == 'student';
  }
}