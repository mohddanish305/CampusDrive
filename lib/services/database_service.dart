import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:campusdrive/models/study_item.dart';
import 'package:campusdrive/models/user_profile.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'study_organizer.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add description column to timetable if it doesn't exist
      // Note: SQLite doesn't support IF NOT EXISTS in ADD COLUMN standardly,
      // but running it safely or checking errors is fine.
      // Ideally we just run it.
      try {
        await db.execute('ALTER TABLE timetable ADD COLUMN description TEXT');
      } catch (e) {
        // Column might already exist if we messed up before, ignore
        debugPrint("Error adding description column: $e");
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE files(
        id TEXT PRIMARY KEY,
        path TEXT,
        name TEXT,
        category TEXT,
        type TEXT,
        added_date INTEGER,
        tags TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items(
        id TEXT PRIMARY KEY,
        name TEXT,
        path TEXT,
        parent_id TEXT,
        type INTEGER,
        created_at INTEGER,
        modified_at INTEGER,
        is_synced INTEGER DEFAULT 0,
        supabase_path TEXT,
        supabase_url TEXT,
        is_favorite INTEGER DEFAULT 0,
        user_id TEXT
      )
    ''');

    // Initialize Default Folders
    await _initDefaultFolders(db);

    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content_json TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE timetable(
        id TEXT PRIMARY KEY,
        day INTEGER,
        subject TEXT,
        start_time TEXT,
        end_time TEXT,
        room TEXT,
        color INTEGER,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        date_time INTEGER,
        type TEXT,
        is_active INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        full_name TEXT,
        email TEXT,
        college_name TEXT,
        branch TEXT,
        year TEXT,
        profile_image_path TEXT
      )
    ''');

    // Initialize default profile
    await db.insert('user_profile', {
      'id': 1,
      'full_name': 'MOHD DANISH',
      'email': 'digibuisnessdanish@gmail.com',
      'college_name': 'JITS',
      'branch': 'CSE',
      'year': '3',
      'profile_image_path': null,
    });
  }

  Future<void> _initDefaultFolders(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final folders = [
      {
        'id': 'folder_timetable',
        'name': 'Time Table',
        'path': '/Time Table',
        'parent_id': null,
        'type': 0, // FileType.folder.index
        'created_at': now,
        'modified_at': now,
        'is_synced': 0,
        'is_favorite': 1,
      },
      {
        'id': 'folder_assignments',
        'name': 'Assignments',
        'path': '/Assignments',
        'parent_id': null,
        'type': 0, // FileType.folder.index
        'created_at': now,
        'modified_at': now,
        'is_synced': 0,
        'is_favorite': 1,
      },
      {
        'id': 'folder_notes',
        'name': 'Notes',
        'path': '/Notes',
        'parent_id': null,
        'type': 0, // FileType.folder.index
        'created_at': now,
        'modified_at': now,
        'is_synced': 0,
        'is_favorite': 1,
      },
    ];

    for (var folder in folders) {
      await db.insert('items', folder);
    }
  }

  // File Operations
  Future<void> insertFile(Map<String, dynamic> file) async {
    // Also insert into items table for unified view
    final db = await database;
    try {
      await db.insert(
        'files',
        file,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Convert legacy file map to items map
      // This is a temporary bridge. Ideally we move everything to items.
      int typeIndex = 7; // FileType.other
      String ext = file['type'] ?? '';
      if (ext.contains('pdf')) {
        typeIndex = 1;
      } else if (ext.contains('doc')) {
        typeIndex = 2;
      } else if (ext.contains('xls')) {
        typeIndex = 3;
      } else if (ext.contains('png') || ext.contains('jpg')) {
        typeIndex = 4;
      }

      await db.insert('items', {
        'id': file['id'],
        'name': file['name'],
        'path': file['path'],
        'parent_id': null, // Root for now, or need to pass parentId
        'type': typeIndex,
        'created_at': file['added_date'],
        'modified_at': file['added_date'],
        'is_synced': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Ignore duplicates or errors for now
    }
  }

  Future<List<Map<String, dynamic>>> getFiles({
    String? category,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> args = [];

    if (category != null) {
      whereClause += 'category = ?';
      args.add(category);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'name LIKE ?';
      args.add('%$searchQuery%');
    }

    return await db.query(
      'files',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: args.isEmpty ? null : args,
    );
  }

  Future<void> deleteFile(String id) async {
    final db = await database;
    await db.delete('files', where: 'id = ?', whereArgs: [id]);
  }

  // Item Operations (StudyItem)
  Future<void> insertItem(StudyItem item) async {
    final db = await database;
    await db.insert(
      'items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<StudyItem?> getItem(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return StudyItem.fromMap(maps.first);
    }
    return null;
  }

  Future<List<StudyItem>> getItems({
    String? parentId,
    String? userId,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> args = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'name LIKE ?';
      args.add('%$searchQuery%');
    } else {
      if (parentId == null) {
        whereClause = 'parent_id IS NULL';
        // Do NOT add parentId to args
      } else {
        whereClause = 'parent_id = ?';
        args.add(parentId);
      }
    }

    if (userId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'user_id = ?';
      args.add(userId);
    }

    // Only add WHERE if we have conditions
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'type ASC, name ASC',
    );

    return List.generate(maps.length, (i) {
      return StudyItem.fromMap(maps[i]);
    });
  }

  Future<List<StudyItem>> getAllItems({String? userId}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? args;

    if (userId != null) {
      whereClause = 'user_id = ?';
      args = [userId];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: whereClause,
      whereArgs: args,
    );
    return List.generate(maps.length, (i) {
      return StudyItem.fromMap(maps[i]);
    });
  }

  Future<void> updateItem(StudyItem item) async {
    final db = await database;
    await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await database;

    // Recursive delete for children
    final List<Map<String, dynamic>> children = await db.query(
      'items',
      columns: ['id'],
      where: 'parent_id = ?',
      whereArgs: [id],
    );

    for (var child in children) {
      await deleteItem(child['id'] as String);
    }

    await db.delete('items', where: 'id = ?', whereArgs: [id]);

    // Also try checking if it was a distinct file/note in other tables to be clean
    // But since ids are shared or UUIDs, it should be fine.
    // Ideally we should delete from 'files' and 'notes' if matching id exists.
    await db.delete('files', where: 'id = ?', whereArgs: [id]);
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    await db.insert(
      'notes',
      note,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Also insert into items
    await db.insert('items', {
      'id': note['id'],
      'name': note['title'],
      'path': '', // Notes don't have a path
      'parent_id': 'folder_notes', // Put in Notes folder
      'type': 6, // FileType.other
      'created_at': DateTime.fromMillisecondsSinceEpoch(
        note['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ).toIso8601String(),
      'modified_at': DateTime.fromMillisecondsSinceEpoch(
        note['updated_at'],
      ).toIso8601String(),
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateNote(Map<String, dynamic> note) async {
    final db = await database;
    await db.update('notes', note, where: 'id = ?', whereArgs: [note['id']]);

    // Update items table
    await db.update(
      'items',
      {
        'name': note['title'],
        'modified_at': DateTime.fromMillisecondsSinceEpoch(
          note['updated_at'],
        ).toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [note['id']],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // Timetable Operations
  Future<List<Map<String, dynamic>>> getClassesForDay(int day) async {
    final db = await database;
    // Order by start_time. Note: Text sort might be imperfect '10:00 AM' vs '09:00 AM'.
    // Ideally store 24h format or separate unified timestamp.
    // For now, simple text retrieval.
    return await db.query(
      'timetable',
      where: 'day = ?',
      whereArgs: [day],
      orderBy: 'start_time ASC',
    );
  }

  Future<void> insertClass(Map<String, dynamic> classItem) async {
    final db = await database;
    await db.insert(
      'timetable',
      classItem,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteClass(String id) async {
    final db = await database;
    await db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTimetable() async {
    final db = await database;
    await db.delete('timetable');
  }

  // Profile Methods
  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'id = 1',
    );
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert('user_profile', {
      'id': 1,
      ...profile.toMap(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
