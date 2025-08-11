// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class StorageHelper {
//   static const String _productMapKey = 'productMaterialsMap';
//   static const String _quantityMapKey = 'mappingQuantities';
//
//   /// Save mappings to shared preferences
//   static Future<void> saveMappings(
//       Map<int, List<int>> productMaterialsMap,
//       Map<int, Map<int, double>> mappingQuantities,
//       ) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final productMapStrKeys = productMaterialsMap.map(
//           (key, value) => MapEntry(key.toString(), value),
//     );
//
//     final qtyMapStrKeys = mappingQuantities.map((key, value) {
//       final nested = value.map((k, v) => MapEntry(k.toString(), v));
//       return MapEntry(key.toString(), nested);
//     });
//
//     await prefs.setString(_productMapKey, jsonEncode(productMapStrKeys));
//     await prefs.setString(_quantityMapKey, jsonEncode(qtyMapStrKeys));
//   }
//
//   /// Load mappings from shared preferences
//   static Future<(Map<int, List<int>>, Map<int, Map<int, double>>)> loadMappings() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final productMapStr = prefs.getString(_productMapKey);
//     final qtyMapStr = prefs.getString(_quantityMapKey);
//
//     Map<int, List<int>> productMaterialsMap = {};
//     Map<int, Map<int, double>> mappingQuantities = {};
//
//     if (productMapStr != null) {
//       final decoded = jsonDecode(productMapStr) as Map<String, dynamic>;
//       productMaterialsMap = decoded.map((key, value) {
//         final intKey = int.parse(key);
//         final list = List<int>.from(value);
//         return MapEntry(intKey, list);
//       });
//     }
//
//     if (qtyMapStr != null) {
//       final decoded = jsonDecode(qtyMapStr) as Map<String, dynamic>;
//       mappingQuantities = decoded.map((key, value) {
//         final intKey = int.parse(key);
//         final innerMap = (value as Map<String, dynamic>).map(
//               (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
//         );
//         return MapEntry(intKey, innerMap);
//       });
//     }
//
//     return (productMaterialsMap, mappingQuantities);
//   }
// }
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class StorageHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mappings.db');
    print('🗂️ Database Path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ProductMaterialMap (
            productId INTEGER,
            materialId INTEGER,
            quantity REAL,
            PRIMARY KEY (productId, materialId)
          )
        ''');
      },
    );
  }

  /// Save mappings and quantities into SQLite
  static Future<void> saveMappings(
      Map<int, List<int>> productMaterialsMap,
      Map<int, Map<int, double>> mappingQuantities,
      ) async {
    final db = await database;

    print('💾 Saving mappings to DB...');
    print('📦 Products: ${productMaterialsMap.length}');
    print('📦 Quantities: ${mappingQuantities.length}');

    // Clear existing records
    await db.delete('ProductMaterialMap');

    // Insert new mappings
    for (final productId in productMaterialsMap.keys) {
      final materialIds = productMaterialsMap[productId]!;
      for (final materialId in materialIds) {
        final qty = mappingQuantities[productId]?[materialId] ?? 1.0;
        await db.insert(
          'ProductMaterialMap',
          {
            'productId': productId,
            'materialId': materialId,
            'quantity': qty,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ Inserted: Product $productId -> Material $materialId = $qty');
      }
    }
  }

  /// Load mappings and quantities from SQLite
  static Future<(Map<int, List<int>>, Map<int, Map<int, double>>)>
  loadMappings() async {
    final db = await database;
    final result = await db.query('ProductMaterialMap');

    Map<int, List<int>> productMaterialsMap = {};
    Map<int, Map<int, double>> mappingQuantities = {};

    for (var row in result) {
      final int productId = row['productId'] as int;
      final int materialId = row['materialId'] as int;
      final double quantity = (row['quantity'] as num).toDouble();

      productMaterialsMap.putIfAbsent(productId, () => []).add(materialId);
      mappingQuantities.putIfAbsent(productId, () => {})[materialId] = quantity;
    }

    return (productMaterialsMap, mappingQuantities);
  }
}
