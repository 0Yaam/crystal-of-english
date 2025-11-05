import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class User {
  int? id;
  String name;
  int level;
  int streak;
  DateTime? lastLoginDate;
  int goal;
  User({
    this.id,
    required this.name,
    required this.level,
    required this.streak,
    required this.lastLoginDate,
    required this.goal,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'level': level, 'streak': streak};
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      level: map['level'],
      streak: map['streak'],
      lastLoginDate: map['lastLoginDate'] != null
          ? DateTime.parse(map['lastLoginDate'])
          : DateTime.now(),
      goal: map['goal'] ?? 10,
    );
  }
}

class UserDatabase {
  static final UserDatabase instance = UserDatabase._privateConstructor();
  static Database? _database;

  UserDatabase._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      level INTEGER NOT NULL,
      streak INTEGER NOT NULL,
      lastLoginDate TEXT,
      goal INTEGER
    )
    ''');
  }

  Future<void> UpdateGoal(int newGoal) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'goal': newGoal},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
  Future<int> create(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> readAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((e) => User.fromMap(e)).toList();
  }

  Future<int> update(User user) async {
    final db = await instance.database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<User> getUser(int id) async {
    final db = await instance.database;

    // Query theo ID
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);

    // Nếu có kết quả thì trả về dòng đầu tiên, không thì trả null
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      final defaultUser = User(
        id: id,
        name: "Hieu",
        level: 1,
        streak: 5,
        goal: 15,
        lastLoginDate: DateTime.now(),
      );
      try
      {
        await db.insert('users', defaultUser.toMap());
      }
      catch(e)
      {
        print("Error creating default user: $e");
      }
      return defaultUser;
    }
  }

  Future<void> updateStreak() async {
    final db = await instance.database;
    final now = DateTime.now();

    // Lấy user (chỉ có 1)
    final user = await getUser(1); // trả về User object

    // Kiểm tra lastLoginDate
    final lastLogin = user.lastLoginDate;
    int newStreak = user.streak;

    if (lastLogin != null) {
      final difference = now.difference(lastLogin).inDays;

      if (difference == 0) {
        // Cùng ngày -> không tăng
        return;
      } else if (difference == 1) {
        // Liền kề -> tăng streak
        newStreak += 1;
      } else {
        // Ngày gián đoạn -> reset streak
        newStreak = 1;
      }
    } else {
      // Chưa có lastLoginDate -> set streak = 1
      newStreak = 1;
    }

    // Cập nhật lại user
    final updatedUser = User(
      id: user.id,
      name: user.name,
      level: user.level,
      streak: newStreak,
      lastLoginDate: now,
      goal: user.goal,
    );

    await db.update(
      'users',
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
