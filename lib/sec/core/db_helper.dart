import 'dart:async';
import 'package:jouls_labs_demo_app/sec/feature/home/model/upload_file_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' as io;
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper.internal();
  factory DBHelper() => _instance;
  static Database? _db;
  static const String id = 'id';
  static const String fileName = 'fileName';
  static const String fileUrl = 'fileUrl';
  static const String createdAt = 'createdAt';
  static const String userName = 'userName';
  static const String profileImage = 'profileImage';
  static const String email = 'email';
  static const String table = 'FileTable';
  static const String dbName = 'file.db';

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    } else {
      _db = await initDb();
      return _db!;
    }
  }

  DBHelper.internal();
  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    var db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    return db;
  }

  _onCreate(Database db, int version) async {
    await db.execute(
      "CREATE TABLE $table ($id INTEGER,$fileName TEXT, $fileUrl BLOB, $createdAt INTEGER, $userName TEXT, $profileImage TEXT, $email TEXT)",
    );
  }

  Future<UploadedFileModel> saveFiles(UploadedFileModel fileModel) async {
    var dbClient = await db;
    fileModel.id = await dbClient.insert(
      table,
      fileModel.toMap(),
    );

    return fileModel;
  }

  Future<List<UploadedFileModel>> getFiles() async {
    var dbClient = await db;

    List<Map> maps = await dbClient.query(
      table,
      columns: [
        id,
        fileName,
        fileUrl,
        createdAt,
        userName,
        profileImage,
        email,
      ],
    );
    List<UploadedFileModel> files = [];
    if (maps.isNotEmpty) {
      for (int i = 0; i < maps.length; i++) {
        files.clear();
        files.add(
          UploadedFileModel.fromMap(maps[i] as Map<String, dynamic>),
        );
      }
    }
    return files;
  }

  // Update an item by id
  Future<int> updateItem({
    int? id,
    String? fileName,
    int? createdAt,
  }) async {
    var dbClient = await db;

    final data = {
      'fileName': fileName,
      'createdAt': createdAt,
    };

    final result = await dbClient.update(
      table,
      data,
      where: "id = ?",
      whereArgs: [id],
    );
    return result;
  }

  Future close() async {
    var dbClient = await db;
    dbClient.close();
  }
}
