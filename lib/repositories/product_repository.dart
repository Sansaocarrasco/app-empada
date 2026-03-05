import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../core/constants.dart';
import '../models/product.dart';

/// Repositório de operações CRUD para produtos no SQLite.
class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => _dbHelper.database;

  Future<List<Product>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableProducts,
      orderBy: 'name ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<Product?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<void> insert(Product product) async {
    final db = await _db;
    await db.insert(
      AppConstants.tableProducts,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Product product) async {
    final db = await _db;
    await db.update(
      AppConstants.tableProducts,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(
      AppConstants.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Decrementa o estoque de um produto após uma venda.
  Future<void> decrementStock(String productId, int quantity) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE ${AppConstants.tableProducts} SET quantity = quantity - ? WHERE id = ?',
      [quantity, productId],
    );
  }
}
