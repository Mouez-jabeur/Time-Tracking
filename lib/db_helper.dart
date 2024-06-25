import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'time_entry.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  static Database? _database;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'time_entries.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE time_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        start_time TEXT,
        end_time TEXT,
        duration INTEGER
      )
    ''');
  }

  Future<void> insertTimeEntry(TimeEntry entry) async {
    final db = await database;
    await db.insert('time_entries', entry.toMap());
  }

  Future<List<TimeEntry>> getTimeEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('time_entries');

    return List.generate(maps.length, (i) {
      return TimeEntry(
        id: maps[i]['id'],
        title: maps[i]['title'],
        startTime: DateTime.parse(maps[i]['start_time']),
        endTime: DateTime.parse(maps[i]['end_time']),
        duration: Duration(minutes: maps[i]['duration']),
      );
    });
  }
}
