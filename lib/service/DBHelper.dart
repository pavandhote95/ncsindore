import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();

  factory DBHelper() => _instance;

  DBHelper._internal();

  Database? _database;   

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('forms.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);

    return await openDatabase(
      path,
      version: 3, // bump version from 1 to 2
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE forms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        type TEXT,
        timestamp TEXT,
        appCode TEXT,
        code TEXT,
        saveformcode TEXT,
        data TEXT,
        imagePaths TEXT
        docpath TEXT
      )
    ''');
      },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute("ALTER TABLE forms ADD COLUMN appCode TEXT;");
            await db.execute("ALTER TABLE forms ADD COLUMN code TEXT;");
            await db.execute("ALTER TABLE forms ADD COLUMN saveformcode TEXT;");
          }
          if (oldVersion < 3) {
            await db.execute("ALTER TABLE forms ADD COLUMN imagePaths TEXT;");
            // await db.execute('ALTER TABLE forms ADD COLUMN docpath TEXT');


          }
        }
    );

  }

  Future<int> insertForm({
    required String title,
    required String type,
    required String appCode,
    required String code,
    required String saveformcode,
    required Map<String, dynamic> formData,
    Map<String, String>? imagePaths,
    // Map<String, String>? docpath,
  }) async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String();
    return await db.insert('forms', {
      'title': title,
      'type': type,
      'timestamp': timestamp,
      'appCode': appCode,
      'code': code,
      'saveformcode': saveformcode,
      'data': jsonEncode(formData),
      'imagePaths': jsonEncode(imagePaths),
      // 'docpath': jsonEncode(docpath),
    });
  }
  Future<void> resetDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'forms.db');
    await deleteDatabase(path);
    _database = null;  // ✅ add this
    print('Database deleted');
  }
  Future<int> deleteForm(int id) async {
    final db = await database;
    return await db.delete(
      'forms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ${controller.appCode.value}/${controller.code.value}/${controller.saveformcode.value.toString()}
  Future<List<Map<String, dynamic>>> getAllForms() async {
    final db = await database;
    return await db.query('forms');
  }
}
