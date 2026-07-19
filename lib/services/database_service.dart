import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/reminder.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    final path = join(await getDatabasesPath(), 'hatirla_ai.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE reminders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          dateTime TEXT,
          isCompleted INTEGER
        )
        ''');
      },
    );

    return _database!;
  }

  static Future<void> insertReminder(Reminder reminder) async {
    final db = await database;

    await db.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Reminder>> getReminders() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('reminders');

    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  static Future<void> deleteReminder(int id) async {
    final db = await database;

    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateReminder(Reminder reminder) async {
    final db = await database;

    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }
}
