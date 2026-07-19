import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'reminders.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            dateTime TEXT,
            isCompleted INTEGER
          )
        ''');
      },
    );
  }

  // İstediğin düzeltme: Gelecek bildirimler için int tipinde ID döndürür
  static Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  static Future<List<Reminder>> getReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      orderBy: 'dateTime ASC',
    );
    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  // İstediğin düzeltme: Ana ekranda tıklanan görevin durumunu günceller
  static Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
