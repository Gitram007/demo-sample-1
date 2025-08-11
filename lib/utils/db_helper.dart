// import 'dart:io';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
//
// import '../models/product.dart';
// import '../models/material_item.dart';
//
// class DatabaseHelper {
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//   factory DatabaseHelper() => _instance;
//   DatabaseHelper._internal();
//
//   static Database? _db;
//
//   Future<Database> get db async {
//     if (_db != null) return _db!;
//     _db = await _initDb();
//     return _db!;
//   }
//
//   Future<Database> _initDb() async {
//     Directory documentsDirectory = await getApplicationDocumentsDirectory();
//     String path = join(documentsDirectory.path, "product_material.db");
//
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: _onCreate,
//     );
//   }
//
//   Future<void> _onCreate(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE products (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         name TEXT NOT NULL
//       )
//     ''');
//
//     await db.execute('''
//       CREATE TABLE materials (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         name TEXT NOT NULL,
//         qty INTEGER NOT NULL,
//         unit TEXT NOT NULL
//       )
//     ''');
//   }
//
//   // ------------------ Product CRUD ------------------
//
//   Future<int> insertProduct(Product product) async {
//     final dbClient = await db;
//     return await dbClient.insert(
//       'products',
//       {
//         'name': product.name,
//       },
//     );
//   }
//
//   Future<List<Product>> getAllProducts() async {
//     final dbClient = await db;
//     final res = await dbClient.query('products');
//     return res.map((map) => Product(
//       id: map['id'] as int,
//       name: map['name'] as String,
//     )).toList();
//   }
//
//   Future<int> updateProduct(Product product) async {
//     final dbClient = await db;
//     return await dbClient.update(
//       'products',
//       {
//         'name': product.name,
//       },
//       where: 'id = ?',
//       whereArgs: [product.id],
//     );
//   }
//
//   Future<int> deleteProduct(int id) async {
//     final dbClient = await db;
//     return await dbClient.delete(
//       'products',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }
//
//   // ------------------ Material CRUD ------------------
//
//   Future<int> insertMaterial(MaterialItem material) async {
//     final dbClient = await db;
//     return await dbClient.insert(
//       'materials',
//       {
//         'name': material.name,
//         'qty': material.qty,
//         'unit': material.unit,
//       },
//     );
//   }
//
//   Future<List<MaterialItem>> getAllMaterials() async {
//     final dbClient = await db;
//     final res = await dbClient.query('materials');
//     return res.map((map) => MaterialItem(
//       id: map['id'] as int,
//       name: map['name'] as String,
//       qty: map['qty'] as int,
//       unit: map['unit'] as String,
//     )).toList();
//   }
//
//   Future<int> updateMaterial(MaterialItem material) async {
//     final dbClient = await db;
//     return await dbClient.update(
//       'materials',
//       {
//         'name': material.name,
//         'qty': material.qty,
//         'unit': material.unit,
//       },
//       where: 'id = ?',
//       whereArgs: [material.id],
//     );
//   }
//
//   Future<int> deleteMaterial(int id) async {
//     final dbClient = await db;
//     return await dbClient.delete(
//       'materials',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }
// }
// CREATE TABLE product_material_map (
// product_id INTEGER NOT NULL,
// material_id INTEGER NOT NULL,
// PRIMARY KEY(product_id, material_id)
// )

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/product.dart';
import '../models/material_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "product_material.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        unit TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE product_material_map (
        product_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        quantity REAL NOT NULL DEFAULT 1.0,
        PRIMARY KEY(product_id, material_id),
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
        FOREIGN KEY(material_id) REFERENCES materials(id) ON DELETE CASCADE
      )
    ''');
  }

  // ------------------ Product CRUD ------------------

  Future<int> insertProduct(Product product) async {
    final dbClient = await db;
    return await dbClient.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final dbClient = await db;
    final res = await dbClient.query('products');
    return res.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final dbClient = await db;
    return await dbClient.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final dbClient = await db;
    return await dbClient.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------ Material CRUD ------------------

  Future<int> insertMaterial(MaterialItem material) async {
    final dbClient = await db;
    return await dbClient.insert(
      'materials',
      {
        'name': material.name,
        'qty': material.qty,
        'unit': material.unit,
      },
    );
  }

  Future<List<MaterialItem>> getAllMaterials() async {
    final dbClient = await db;
    final res = await dbClient.query('materials');
    return res
        .map((map) => MaterialItem(
      id: map['id'] as int,
      name: map['name'] as String,
      qty: map['qty'] as int,
      unit: map['unit'] as String,
    ))
        .toList();
  }

  Future<int> updateMaterial(MaterialItem material) async {
    final dbClient = await db;
    return await dbClient.update(
      'materials',
      {
        'name': material.name,
        'qty': material.qty,
        'unit': material.unit,
      },
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<int> deleteMaterial(int id) async {
    final dbClient = await db;
    return await dbClient.delete(
      'materials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------ Product-Material Mapping ------------------

  Future<void> mapMaterialToProduct(int productId, int materialId, double quantity) async {
    final dbClient = await db;
    await dbClient.insert(
      'product_material_map',
      {
        'product_id': productId,
        'material_id': materialId,
        'quantity': quantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unmapMaterialFromProduct(int productId, int materialId) async {
    final dbClient = await db;
    await dbClient.delete(
      'product_material_map',
      where: 'product_id = ? AND material_id = ?',
      whereArgs: [productId, materialId],
    );
  }

  Future<Map<int, double>> getMaterialsForProduct(int productId) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'product_material_map',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    return {
      for (var row in res)
        row['material_id'] as int: (row['quantity'] as num).toDouble()
    };
  }

  Future<Map<int, List<int>>> getAllMappings() async {
    final dbClient = await db;
    final res = await dbClient.query('product_material_map');

    Map<int, List<int>> map = {};
    for (var row in res) {
      final pid = row['product_id'] as int;
      final mid = row['material_id'] as int;
      map.putIfAbsent(pid, () => []).add(mid);
    }
    return map;
  }

  Future<Map<int, Map<int, double>>> getAllQuantities() async {
    final dbClient = await db;
    final res = await dbClient.query('product_material_map');

    Map<int, Map<int, double>> qtyMap = {};
    for (var row in res) {
      final pid = row['product_id'] as int;
      final mid = row['material_id'] as int;
      final qty = (row['quantity'] as num).toDouble();

      qtyMap.putIfAbsent(pid, () => {})[mid] = qty;
    }
    return qtyMap;
  }
}
