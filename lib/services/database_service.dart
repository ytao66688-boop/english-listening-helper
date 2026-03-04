import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('english_listening.db');
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

  Future _createDB(Database db, int version) async {
    // 词汇表
    await db.execute('''
      CREATE TABLE words (
        id TEXT PRIMARY KEY,
        word TEXT NOT NULL,
        phonetic TEXT,
        chineseMeaning TEXT NOT NULL,
        level TEXT,
        isKnown INTEGER DEFAULT 0
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_word ON words(word)');
    await db.execute('CREATE INDEX idx_isKnown ON words(isKnown)');

    // 音频文件表
    await db.execute('''
      CREATE TABLE audio_files (
        id TEXT PRIMARY KEY,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL,
        duration INTEGER,
        createdAt TEXT NOT NULL,
        transcriptPath TEXT,
        isProcessed INTEGER DEFAULT 0
      )
    ''');

    // 转写文本表
    await db.execute('''
      CREATE TABLE transcripts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        audioId TEXT NOT NULL,
        word TEXT NOT NULL,
        startTime REAL NOT NULL,
        endTime REAL NOT NULL,
        isUnknown INTEGER DEFAULT 0,
        FOREIGN KEY (audioId) REFERENCES audio_files(id)
      )
    ''');

    // 学习记录表
    await db.execute('''
      CREATE TABLE study_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        audioId TEXT NOT NULL,
        lastPosition INTEGER DEFAULT 0,
        studyTime INTEGER DEFAULT 0,
        lastStudiedAt TEXT,
        FOREIGN KEY (audioId) REFERENCES audio_files(id)
      )
    ''');
  }

  Future<void> initialize() async {
    await database;
  }

  // Words CRUD
  Future<void> insertWord(Word word) async {
    final db = await instance.database;
    await db.insert('words', word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertWords(List<Word> words) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var word in words) {
      batch.insert('words', word.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Word>> getWordsByLetter(String letter) async {
    final db = await instance.database;
    final result = await db.query(
      'words',
      where: 'word LIKE ?',
      whereArgs: ['$letter%'],
      orderBy: 'word ASC',
    );
    return result.map((e) => Word.fromMap(e)).toList();
  }

  Future<List<Word>> getUnknownWords() async {
    final db = await instance.database;
    final result = await db.query(
      'words',
      where: 'isKnown = 0',
      orderBy: 'word ASC',
    );
    return result.map((e) => Word.fromMap(e)).toList();
  }

  Future<void> updateWordKnownStatus(String wordId, bool isKnown) async {
    final db = await instance.database;
    await db.update(
      'words',
      {'isKnown': isKnown ? 1 : 0},
      where: 'id = ?',
      whereArgs: [wordId],
    );
  }

  Future<bool> isWordKnown(String word) async {
    final db = await instance.database;
    final result = await db.query(
      'words',
      where: 'word = ? AND isKnown = 1',
      whereArgs: [word.toLowerCase()],
    );
    return result.isNotEmpty;
  }

  Future<Word?> getWordByText(String word) async {
    final db = await instance.database;
    final result = await db.query(
      'words',
      where: 'word = ?',
      whereArgs: [word.toLowerCase()],
    );
    if (result.isNotEmpty) {
      return Word.fromMap(result.first);
    }
    return null;
  }

  Future<int> getKnownWordsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM words WHERE isKnown = 1',
    );
    return result.first['count'] as int;
  }

  Future<int> getTotalWordsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return result.first['count'] as int;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}