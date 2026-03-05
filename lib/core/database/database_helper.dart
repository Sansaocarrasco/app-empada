import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants.dart';

/// Singleton que gerencia o banco de dados SQLite local.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Migração de versões anteriores.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: adiciona colunas de dados do pagador (Mercado Pago)
      await db.execute(
          'ALTER TABLE ${AppConstants.tableSales} ADD COLUMN payer_name TEXT');
      await db.execute(
          'ALTER TABLE ${AppConstants.tableSales} ADD COLUMN payer_email TEXT');
      await db.execute(
          'ALTER TABLE ${AppConstants.tableSales} ADD COLUMN approved_at TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabela de produtos
    await db.execute('''
      CREATE TABLE ${AppConstants.tableProducts} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        image_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabela de vendas (v2: inclui dados do pagador)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSales} (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_status TEXT NOT NULL DEFAULT 'pending',
        mercado_pago_id TEXT,
        payment_method TEXT,
        payer_name TEXT,
        payer_email TEXT,
        approved_at TEXT
      )
    ''');

    // Tabela de itens de venda
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSaleItems} (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES ${AppConstants.tableSales}(id)
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
