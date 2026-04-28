import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'common_foods_data.dart';

class FoodDatabaseService {
  FoodDatabaseService._();
  static final FoodDatabaseService instance = FoodDatabaseService._();

  static const _dbName = 'foods.db';
  static const _dbVersion = 18;
  static const _table = 'foods';

  Database? _db;

  Future<Database> get _database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), _dbName);
    try {
      // Pre-upgrade: sync custom foods to Firestore BEFORE the table is dropped
      final probe = await openDatabase(dbPath, singleInstance: false);
      final oldVersion = await probe.getVersion();
      if (oldVersion > 0 && oldVersion < _dbVersion) {
        await _syncCustomFoodsBeforeUpgrade(probe);
      }
      await probe.close();
    } catch (_) {
      // DB doesn't exist or is corrupted — nothing to sync
    }

    try {
      return await openDatabase(
        dbPath,
        version: _dbVersion,
        onCreate: _createTable,
        onUpgrade: (db, oldVersion, newVersion) async {
          await db.execute('DROP TABLE IF EXISTS $_table');
          await db.execute('DROP TABLE IF EXISTS _foods_custom_backup');
          await _createTable(db, newVersion);
        },
      );
    } catch (_) {
      await deleteDatabase(dbPath);
      return openDatabase(
        dbPath,
        version: _dbVersion,
        onCreate: _createTable,
      );
    }
  }

  /// Syncs local custom foods to Firestore before a DB upgrade drops the table.
  Future<void> _syncCustomFoodsBeforeUpgrade(Database db) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Check if table exists
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [_table],
      );
      if (tableCheck.isEmpty) return;

      final allRows = await db.query(_table);
      if (allRows.isEmpty) return;

      // Load bundled names to identify custom foods
      final jsonStr =
          await rootBundle.loadString('assets/foods/common_foods.json');
      final List<dynamic> items = json.decode(jsonStr) as List<dynamic>;
      final bundledNames = <String>{
        for (final m in items) (m['name'] as String).toLowerCase(),
      };

      final customRows = allRows
          .where(
              (r) => !bundledNames.contains((r['nameLower'] as String?) ?? ''))
          .toList();

      if (customRows.isEmpty) return;

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(uid);
      final batch = FirebaseFirestore.instance.batch();
      final collection = userDoc.collection('custom_foods');

      for (final row in customRows) {
        final name = row['name'] as String? ?? '';
        if (name.isEmpty) continue;
        final docId =
            name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        batch.set(collection.doc(docId), {
          'name': name,
          'servingSize': row['servingSize'] ?? '100g',
          'calories': row['calories'] ?? 0,
          'protein': row['protein'] ?? 0,
          'carbs': row['carbs'] ?? 0,
          'fat': row['fat'] ?? 0,
          'fiber': row['fiber'] ?? 0,
          'sodium': row['sodium'] ?? 0,
          'sugar': row['sugar'] ?? 0,
          'cholesterol': row['cholesterol'] ?? 0,
          'category': row['category'] ?? 'Other',
        });
      }
      await batch.commit();
      await userDoc.set({'customFoodsSynced': true}, SetOptions(merge: true));
    } catch (_) {
      // Best effort — don't block upgrade if Firestore is unavailable
    }
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nameLower TEXT NOT NULL,
        servingSize TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL,
        sodium REAL,
        sugar REAL,
        cholesterol REAL,
        iron REAL,
        calcium REAL,
        potassium REAL,
        vitaminA REAL,
        vitaminB12 REAL,
        vitaminC REAL,
        vitaminD REAL,
        zinc REAL,
        magnesium REAL,
        vitaminE REAL,
        vitaminK REAL,
        vitaminB6 REAL,
        folate REAL,
        phosphorus REAL,
        selenium REAL,
        manganese REAL,
        category TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_name_lower ON $_table (nameLower)');
    await db.execute(
        'CREATE INDEX idx_category ON $_table (category)');
  }

  /// Call once at app startup (e.g. in splash screen).
  /// Seeds the DB from the bundled JSON asset on first launch.
  /// Returns `true` if seeding was performed (first launch).
  Future<bool> initialize() async {
    final db = await _database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_table'));
    if (count != null && count > 0) return false;

    // First launch – seed from asset
    final jsonStr =
        await rootBundle.loadString('assets/foods/common_foods.json');
    final List<dynamic> items = json.decode(jsonStr) as List<dynamic>;

    const batchSize = 500;
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, items.length);
      final batch = db.batch();
      for (var j = i; j < end; j++) {
        final m = items[j] as Map<String, dynamic>;
        batch.insert(_table, {
          ...m,
          'nameLower': (m['name'] as String).toLowerCase(),
        });
      }
      await batch.commit(noResult: true);
    }
    // Restore user-created custom foods from Firestore in background
    _restoreCustomFoodsFromFirestore(db);

    return true;
  }

  /// One-time migration: upload any local custom foods to Firestore so they
  /// survive future DB upgrades. Call after DB is open and seeded.
  /// Safe to call multiple times — skips if already synced.
  Future<void> syncCustomFoodsToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Check if we already synced
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final userData = await userDoc.get();
    if (userData.data()?['customFoodsSynced'] == true) return;

    final db = await _database;

    // Load bundled names to identify which local foods are custom
    final jsonStr =
        await rootBundle.loadString('assets/foods/common_foods.json');
    final List<dynamic> items = json.decode(jsonStr) as List<dynamic>;
    final bundledNames = <String>{
      for (final m in items) (m['name'] as String).toLowerCase(),
    };

    final allRows = await db.query(_table);
    final customRows = allRows
        .where((r) => !bundledNames.contains((r['nameLower'] as String?) ?? ''))
        .toList();

    if (customRows.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      final collection = userDoc.collection('custom_foods');
      for (final row in customRows) {
        final name = row['name'] as String? ?? '';
        if (name.isEmpty) continue;
        final docId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        batch.set(collection.doc(docId), {
          'name': name,
          'servingSize': row['servingSize'] ?? '100g',
          'calories': row['calories'] ?? 0,
          'protein': row['protein'] ?? 0,
          'carbs': row['carbs'] ?? 0,
          'fat': row['fat'] ?? 0,
          'fiber': row['fiber'] ?? 0,
          'sodium': row['sodium'] ?? 0,
          'sugar': row['sugar'] ?? 0,
          'cholesterol': row['cholesterol'] ?? 0,
          'category': row['category'] ?? 'Other',
        });
      }
      await batch.commit();
    }

    // Mark as synced so we don't repeat this
    await userDoc.set({'customFoodsSynced': true}, SetOptions(merge: true));
  }

  void _restoreCustomFoodsFromFirestore(Database db) {
    Future(() async {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('custom_foods')
            .get();

        if (snapshot.docs.isEmpty) return;

        final batch = db.batch();
        for (final doc in snapshot.docs) {
          final d = doc.data();
          final name = d['name'] as String? ?? '';
          if (name.isEmpty) continue;
          batch.insert(_table, {
            'name': name,
            'nameLower': name.toLowerCase(),
            'servingSize': d['servingSize'] ?? '100g',
            'calories': (d['calories'] as num?)?.toDouble() ?? 0,
            'protein': (d['protein'] as num?)?.toDouble() ?? 0,
            'carbs': (d['carbs'] as num?)?.toDouble() ?? 0,
            'fat': (d['fat'] as num?)?.toDouble() ?? 0,
            'fiber': (d['fiber'] as num?)?.toDouble() ?? 0,
            'sodium': (d['sodium'] as num?)?.toDouble() ?? 0,
            'sugar': (d['sugar'] as num?)?.toDouble() ?? 0,
            'cholesterol': (d['cholesterol'] as num?)?.toDouble() ?? 0,
            'category': d['category'] ?? 'Other',
          });
        }
        await batch.commit(noResult: true);
      } catch (_) {}
    });
  }

  /// Full-text-ish search on name (case-insensitive via nameLower column).
  Future<List<CommonFoodItem>> searchByName(String query,
      {int limit = 50}) async {
    final db = await _database;
    final q = query.toLowerCase();
    final rows = await db.query(
      _table,
      where: 'nameLower LIKE ?',
      whereArgs: ['%$q%'],
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  /// Distinct category list, alphabetically sorted.
  Future<List<String>> getCategories() async {
    final db = await _database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM $_table WHERE category != \'\' ORDER BY category');
    return rows.map((r) => r['category'] as String).toList();
  }

  /// Foods in a category.
  Future<List<CommonFoodItem>> getFoodsByCategory(String category,
      {int limit = 200, int offset = 0}) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name',
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromRow).toList();
  }

  /// Number of items per category – for UI display.
  Future<Map<String, int>> getCategoryCounts() async {
    final db = await _database;
    final rows = await db.rawQuery(
        'SELECT category, COUNT(*) as cnt FROM $_table WHERE category != \'\' GROUP BY category ORDER BY category');
    return {for (final r in rows) r['category'] as String: r['cnt'] as int};
  }

  static const _validNutrientColumns = {
    'calories', 'protein', 'carbs', 'fat', 'fiber', 'sodium', 'sugar',
    'cholesterol', 'iron', 'calcium', 'potassium', 'vitaminA', 'vitaminB12',
    'vitaminC', 'vitaminD', 'zinc', 'magnesium', 'vitaminE', 'vitaminK',
    'vitaminB6', 'folate', 'phosphorus', 'selenium', 'manganese',
  };

  /// Get foods ranked by a specific nutrient column, descending.
  /// Deduplicates by nameLower (keeps the entry with highest value).
  Future<List<CommonFoodItem>> getTopFoodsByNutrient(
    String nutrientColumn, {int limit = 50}
  ) async {
    if (!_validNutrientColumns.contains(nutrientColumn)) {
      throw ArgumentError('Invalid nutrient column: $nutrientColumn');
    }
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT * FROM $_table
      WHERE id IN (
        SELECT id FROM (
          SELECT id, ROW_NUMBER() OVER (PARTITION BY nameLower ORDER BY $nutrientColumn DESC) AS rn
          FROM $_table
          WHERE $nutrientColumn > 0
        ) WHERE rn = 1
      )
      ORDER BY $nutrientColumn DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(_fromRow).toList();
  }

  /// Search foods within a calorie range, sorted by closest to target.
  Future<List<CommonFoodItem>> searchByCalorieRange(
    int min,
    int max, {
    int target = 0,
    int limit = 50,
  }) async {
    final db = await _database;
    final sortTarget = target > 0 ? target : (min + max) ~/ 2;
    final rows = await db.rawQuery('''
      SELECT * FROM $_table
      WHERE calories BETWEEN ? AND ?
      ORDER BY ABS(calories - ?) ASC
      LIMIT ?
    ''', [min, max, sortTarget, limit]);
    return rows.map(_fromRow).toList();
  }

  /// Insert a user-created food into the local database.
  /// Skips insert if a food with the same name already exists.
  Future<void> insertFood(CommonFoodItem food) async {
    final db = await _database;
    final existing = await db.query(
      _table,
      where: 'nameLower = ?',
      whereArgs: [food.name.toLowerCase()],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    await db.insert(_table, {
      'name': food.name,
      'nameLower': food.name.toLowerCase(),
      'servingSize': food.servingSize,
      'calories': food.calories,
      'protein': food.protein,
      'carbs': food.carbs,
      'fat': food.fat,
      'fiber': food.fiber,
      'sodium': food.sodium,
      'sugar': food.sugar,
      'cholesterol': food.cholesterol,
      'iron': food.iron,
      'calcium': food.calcium,
      'potassium': food.potassium,
      'vitaminA': food.vitaminA,
      'vitaminB12': food.vitaminB12,
      'vitaminC': food.vitaminC,
      'vitaminD': food.vitaminD,
      'zinc': food.zinc,
      'magnesium': food.magnesium,
      'vitaminE': food.vitaminE,
      'vitaminK': food.vitaminK,
      'vitaminB6': food.vitaminB6,
      'folate': food.folate,
      'phosphorus': food.phosphorus,
      'selenium': food.selenium,
      'manganese': food.manganese,
      'category': food.category,
    });
  }

  /// Get a single food by exact name for detail view.
  Future<CommonFoodItem?> getFoodByName(String name) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'nameLower = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  static CommonFoodItem _fromRow(Map<String, dynamic> r) => CommonFoodItem(
        name: r['name'] as String,
        servingSize: r['servingSize'] as String,
        calories: (r['calories'] as num).toDouble(),
        protein: (r['protein'] as num).toDouble(),
        carbs: (r['carbs'] as num).toDouble(),
        fat: (r['fat'] as num).toDouble(),
        fiber: (r['fiber'] as num? ?? 0).toDouble(),
        sodium: (r['sodium'] as num? ?? 0).toDouble(),
        sugar: (r['sugar'] as num? ?? 0).toDouble(),
        cholesterol: (r['cholesterol'] as num? ?? 0).toDouble(),
        iron: (r['iron'] as num? ?? 0).toDouble(),
        calcium: (r['calcium'] as num? ?? 0).toDouble(),
        potassium: (r['potassium'] as num? ?? 0).toDouble(),
        vitaminA: (r['vitaminA'] as num? ?? 0).toDouble(),
        vitaminB12: (r['vitaminB12'] as num? ?? 0).toDouble(),
        vitaminC: (r['vitaminC'] as num? ?? 0).toDouble(),
        vitaminD: (r['vitaminD'] as num? ?? 0).toDouble(),
        zinc: (r['zinc'] as num? ?? 0).toDouble(),
        magnesium: (r['magnesium'] as num? ?? 0).toDouble(),
        vitaminE: (r['vitaminE'] as num? ?? 0).toDouble(),
        vitaminK: (r['vitaminK'] as num? ?? 0).toDouble(),
        vitaminB6: (r['vitaminB6'] as num? ?? 0).toDouble(),
        folate: (r['folate'] as num? ?? 0).toDouble(),
        phosphorus: (r['phosphorus'] as num? ?? 0).toDouble(),
        selenium: (r['selenium'] as num? ?? 0).toDouble(),
        manganese: (r['manganese'] as num? ?? 0).toDouble(),
        category: r['category'] as String? ?? '',
      );
}
