import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../models/result.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('exams.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
    }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        userType TEXT NOT NULL
      )
    ''');
    // Exams table
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        teacherId INTEGER NOT NULL,
        timeLimit INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (teacherId) REFERENCES users (id)
      )
    ''');
    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        examId INTEGER NOT NULL,
        questionText TEXT NOT NULL,
        questionType TEXT NOT NULL,
        options TEXT,
        correctAnswer TEXT NOT NULL,
        points INTEGER NOT NULL,
        FOREIGN KEY (examId) REFERENCES exams (id)
      )
    ''');

    // Results table
    await db.execute('''
      CREATE TABLE results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        examId INTEGER NOT NULL,
        studentId INTEGER NOT NULL,
        score INTEGER NOT NULL,
        totalPoints INTEGER NOT NULL,
        completedAt TEXT NOT NULL,
        FOREIGN KEY (examId) REFERENCES exams (id),
        FOREIGN KEY (studentId) REFERENCES users (id)
      )
    ''');
    // Insert default users
    await db.insert('users', {
      'username': 'teacher1',
      'password': '123456',
      'userType': 'teacher'
    });

    await db.insert('users', {
      'username': 'student1',
      'password': '123456',
      'userType': 'student'
    });
  }
  // User operations
  // ✅ تسجيل مستخدم جديد
  Future<int> registerUser(User user) async {
    final db = await instance.database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      // إذا كان اسم المستخدم موجود مسبقاً
      return -1;
    }
  }
  // ✅ تسجيل الدخول
  Future<User?> loginUser(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }
  // Exam operations
  Future<int> createExam(Exam exam) async {
    final db = await instance.database;
    return await db.insert('exams', exam.toMap());
  }

  Future<List<Exam>> getExams() async {
    final db = await instance.database;
    final result = await db.query('exams');
    return result.map((map) => Exam.fromMap(map)).toList();
  }
  // Question operations
  Future<int> createQuestion(Question question) async {
    final db = await instance.database;
    return await db.insert('questions', question.toMap());
  }

  Future<List<Question>> getQuestionsByExam(int examId) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'examId = ?',
      whereArgs: [examId],
    );
    return result.map((map) => Question.fromMap(map)).toList();
  }
  // Result operations
  Future<int> saveResult(ExamResult result) async {
    final db = await instance.database;
    return await db.insert('results', result.toMap());
  }

  Future<List<ExamResult>> getResultsByStudent(int studentId) async {
    final db = await instance.database;
    final result = await db.query(
      'results',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    return result.map((map) => ExamResult.fromMap(map)).toList();
  }
  // ------------------------------
  // 👉 ملاحظات للتطوير مستقبلاً:
  //
  // - إضافة جدول جديد للدرجات (grades) والمواد (courses).
  // - إنشاء دوال لإدارة الدرجات:
  //     إضافة درجة جديدة.
  //    تعديل درجة موجودة.
  //    عرض درجات طالب.
  // - Excelدوال لاستيراد بيانات الطلاب من ملفات :
  // - لربط مع نظام الجامعة    APIخارجي //

}


