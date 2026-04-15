import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stall_pos.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        purchasePrice REAL NOT NULL,
        retailPrice REAL NOT NULL,
        wholesalePrice REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT '个',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        totalAmount REAL NOT NULL,
        totalCost REAL NOT NULL,
        totalProfit REAL NOT NULL,
        saleDate TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        costPrice REAL NOT NULL,
        profit REAL NOT NULL,
        saleDate TEXT NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_sales_date ON sales(saleDate)');
    await db.execute('CREATE INDEX idx_sale_items_date ON sale_items(saleDate)');
  }

  // ==================== 商品管理 ====================
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    return await db.update('products', product, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 销售开单 ====================
  Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    return await db.insert('sales', sale);
  }

  Future<int> insertSaleItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('sale_items', item);
  }

  Future<List<Map<String, dynamic>>> getSalesByDateRange(String start, String end) async {
    final db = await database;
    return await db.query(
      'sales',
      where: 'saleDate >= ? AND saleDate <= ?',
      whereArgs: [start, end],
      orderBy: 'saleDate DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getSaleItemsBySaleId(int saleId) async {
    final db = await database;
    return await db.query('sale_items', where: 'saleId = ?', whereArgs: [saleId]);
  }

  // ==================== 统计查询 ====================
  Future<Map<String, dynamic>> getDailyStats(String date) async {
    final db = await database;
    final start = '$date 00:00:00';
    final end = '$date 23:59:59';

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(totalAmount), 0) as totalRevenue,
        COALESCE(SUM(totalCost), 0) as totalCost,
        COALESCE(SUM(totalProfit), 0) as totalProfit,
        COUNT(*) as orderCount
      FROM sales
      WHERE saleDate >= ? AND saleDate <= ?
    ''', [start, end]);

    return result.first;
  }

  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    final db = await database;
    final start = '$year-${month.toString().padLeft(2, '0')}-01 00:00:00';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final end = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01 00:00:00';

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(totalAmount), 0) as totalRevenue,
        COALESCE(SUM(totalCost), 0) as totalCost,
        COALESCE(SUM(totalProfit), 0) as totalProfit,
        COUNT(*) as orderCount
      FROM sales
      WHERE saleDate >= ? AND saleDate < ?
    ''', [start, end]);

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getCustomRangeStats(String start, String end) async {
    final db = await database;
    final startFull = '$start 00:00:00';
    final endFull = '$end 23:59:59';

    return await db.rawQuery('''
      SELECT 
        DATE(saleDate) as date,
        SUM(totalAmount) as totalRevenue,
        SUM(totalCost) as totalCost,
        SUM(totalProfit) as totalProfit,
        COUNT(*) as orderCount
      FROM sales
      WHERE saleDate >= ? AND saleDate <= ?
      GROUP BY DATE(saleDate)
      ORDER BY date DESC
    ''', [startFull, endFull]);
  }

  Future<List<Map<String, dynamic>>> getTopProducts(String start, String end, {int limit = 10}) async {
    final db = await database;
    final startFull = '$start 00:00:00';
    final endFull = '$end 23:59:59';

    return await db.rawQuery('''
      SELECT 
        productId,
        productName,
        SUM(quantity) as totalQuantity,
        SUM(profit) as totalProfit,
        COUNT(*) as orderCount
      FROM sale_items
      WHERE saleDate >= ? AND saleDate <= ?
      GROUP BY productId
      ORDER BY totalQuantity DESC
      LIMIT ?
    ''', [startFull, endFull, limit]);
  }
}
