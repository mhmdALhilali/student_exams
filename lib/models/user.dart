class User {
  final int? id;
  final String username;
  final String password;
  final String userType; // 'teacher' or 'student'

  User({
    this.id,
    required this.username,
    required this.password,
    required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'userType': userType,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      userType: map['userType'],
    );
  }
}