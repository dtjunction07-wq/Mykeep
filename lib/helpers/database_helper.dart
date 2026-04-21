import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mykeep.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        color TEXT DEFAULT '#FFFFFF',
        isPinned INTEGER DEFAULT 0,
        isLocked INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0,
        category TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  // INSERT
  Future<int> insertNote(NoteModel note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  // GET ALL (not deleted)
  Future<List<NoteModel>> getAllNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  // GET TRASH
  Future<List<NoteModel>> getTrashNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'isDeleted = ?',
      whereArgs: [1],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  // UPDATE
  Future<int> updateNote(NoteModel note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // SOFT DELETE (move to trash)
  Future<int> softDeleteNote(int id) async {
    final db = await database;
    return await db.update(
      'notes',
      {'isDeleted': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // RESTORE from trash
  Future<int> restoreNote(int id) async {
    final db = await database;
    return await db.update(
      'notes',
      {'isDeleted': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // PERMANENT DELETE
  Future<int> permanentDeleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // EMPTY TRASH
  Future<int> emptyTrash() async {
    final db = await database;
    return await db.delete('notes', where: 'isDeleted = ?', whereArgs: [1]);
  }

  // SEARCH
  Future<List<NoteModel>> searchNotes(String query) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'isDeleted = 0 AND (title LIKE ? OR content LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  // GET BY CATEGORY
  Future<List<NoteModel>> getNotesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'isDeleted = 0 AND category = ?',
      whereArgs: [category],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  // GET ALL CATEGORIES
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT category FROM notes WHERE isDeleted = 0 AND category IS NOT NULL',
    );
    return maps
        .map((m) => m['category'] as String)
        .where((c) => c.isNotEmpty)
        .toList();
  }
}
