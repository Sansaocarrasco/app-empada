import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../core/constants.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

/// Repositório de vendas e itens de venda no SQLite.
class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => _dbHelper.database;

  // ── Sales ────────────────────────────────────────────────

  Future<List<Sale>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableSales,
      orderBy: 'date DESC',
    );
    return maps.map(Sale.fromMap).toList();
  }

  Future<List<Sale>> getByDay(DateTime day) async {
    final db = await _db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final maps = await db.query(
      AppConstants.tableSales,
      where: "date >= ? AND date < ? AND payment_status = 'approved'",
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map(Sale.fromMap).toList();
  }

  Future<List<Sale>> getLast30Days() async {
    final db = await _db;
    final since = DateTime.now().subtract(const Duration(days: 30));
    final maps = await db.query(
      AppConstants.tableSales,
      where: "date >= ? AND payment_status = 'approved'",
      whereArgs: [since.toIso8601String()],
      orderBy: 'date ASC',
    );
    return maps.map(Sale.fromMap).toList();
  }

  Future<void> insert(Sale sale) async {
    final db = await _db;
    await db.insert(
      AppConstants.tableSales,
      sale.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Sale?> getById(String saleId) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableSales,
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Sale.fromMap(maps.first);
  }

  Future<void> updateStatus(String saleId, PaymentStatus status, {String? mpId}) async {
    final db = await _db;
    await db.update(
      AppConstants.tableSales,
      {
        'payment_status': status.name,
        if (mpId != null) 'mercado_pago_id': mpId,
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  // ── Sale Items ───────────────────────────────────────────

  Future<List<SaleItem>> getItemsBySale(String saleId) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableSaleItems,
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map(SaleItem.fromMap).toList();
  }

  Future<void> insertItems(List<SaleItem> items) async {
    final db = await _db;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        AppConstants.tableSaleItems,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Agrega total vendido por produto (para gráfico de barras)
  Future<List<Map<String, dynamic>>> getSalesByProduct() async {
    final db = await _db;
    return db.rawQuery('''
      SELECT si.product_name, SUM(si.quantity * si.unit_price) as total
      FROM ${AppConstants.tableSaleItems} si
      JOIN ${AppConstants.tableSales} s ON s.id = si.sale_id
      WHERE s.payment_status = 'approved'
      GROUP BY si.product_name
      ORDER BY total DESC
      LIMIT 10
    ''');
  }

  /// Agrega vendas por dia dos últimos 30 dias (para gráfico de linha)
  Future<List<Map<String, dynamic>>> getDailySales() async {
    final db = await _db;
    final since = DateTime.now().subtract(const Duration(days: 30));
    return db.rawQuery('''
      SELECT DATE(date) as day, SUM(total_amount) as total
      FROM ${AppConstants.tableSales}
      WHERE payment_status = 'approved' AND date >= ?
      GROUP BY DATE(date)
      ORDER BY day ASC
    ''', [since.toIso8601String()]);
  }
}
