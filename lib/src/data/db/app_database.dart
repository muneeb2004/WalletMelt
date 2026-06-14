import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../constants/categories.dart';
import '../schema/database_schema.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, DatabaseSchema.databaseName);
    _database = await openDatabase(
      path,
      version: DatabaseSchema.currentVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await db.execute(DatabaseSchema.createCategories);
        await db.execute(DatabaseSchema.createExpenses);
        await db.execute(DatabaseSchema.createGroceryItems);
        await db.execute(DatabaseSchema.createBudgets);
        await db.execute(DatabaseSchema.createSyncMetadata);
        for (final index in DatabaseSchema.indexes) {
          await db.execute(index);
        }
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Future migrations are intentionally centralized here to keep UI code
        // independent from storage evolution.
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        // Drift owns the V2 additive schema. The legacy sqflite runtime path
        // still needs to open that upgraded file while expense CRUD migrates.
      },
    );
    return _database!;
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final batch = db.batch();
    for (final category in buildDefaultCategories(DateTime.now())) {
      batch.insert('categories', category.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final existing = _database;
    if (existing == null) return;
    await existing.close();
    _database = null;
  }
}
