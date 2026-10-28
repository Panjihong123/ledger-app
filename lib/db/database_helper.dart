import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/ledger.dart';
import '../models/transaction.dart';

/// SQLite 单例封装：建表、初始化默认数据、各类 CRUD 与统计查询
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();

  Future<Database> get db async => _db ??= await _init();

  Future<Database> _init() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'ledger.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
        'CREATE TABLE ledgers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, isDefault INTEGER)');
    await db.execute(
        'CREATE TABLE accounts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, initialBalance REAL)');
    await db.execute(
        'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, color INTEGER, icon TEXT)');
    await db.execute(
        'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, ledgerId INTEGER, accountId INTEGER, categoryId INTEGER, type TEXT, amount REAL, date INTEGER, note TEXT)');

    // 默认账本
    await db.insert('ledgers', {'name': '默认账本', 'isDefault': 1});

    // 默认支出分类
    final expenses = [
      ['餐饮', 0xFFEF5350, '🍚'],
      ['水果', 0xFF66BB6A, '🍎'],
      ['水电费', 0xFF42A5F5, '💡'],
      ['房租', 0xFFAB47BC, '🏠'],
      ['停车费', 0xFF26A69A, '🅿️'],
      ['交通', 0xFF26C6DA, '🚌'],
      ['购物', 0xFFEC407A, '🛍️'],
      ['其他', 0xFF78909C, '📦'],
    ];
    // 默认收入分类
    final incomes = [
      ['工资', 0xFF42A5F5, '💰'],
      ['兼职', 0xFF66BB6A, '🧰'],
      ['红包', 0xFFEF5350, '🧧'],
      ['其他', 0xFF78909C, '📦'],
    ];
    for (final e in expenses) {
      await db.insert('categories',
          {'name': e[0], 'type': 'expense', 'color': e[1], 'icon': e[2]});
    }
    for (final e in incomes) {
      await db.insert('categories',
          {'name': e[0], 'type': 'income', 'color': e[1], 'icon': e[2]});
    }

    // 默认现金账户
    await db.insert('accounts', {'name': '现金', 'type': 'cash', 'initialBalance': 0});
  }

  /* ---------------- 账本 ---------------- */
  Future<List<Ledger>> getLedgers() async {
    final d = await db;
    return (await d.query('ledgers')).map(Ledger.fromMap).toList();
  }

  Future<int> insertLedger(Ledger l) async =>
      (await db).insert('ledgers', l.toMap());

  Future<int> updateLedger(Ledger l) async => (await db)
      .update('ledgers', l.toMap(), where: 'id=?', whereArgs: [l.id]);

  Future<int> deleteLedger(int id) async =>
      (await db).delete('ledgers', where: 'id=?', whereArgs: [id]);

  Future<int> countTxnByLedger(int id) async {
    final d = await db;
    final r = await d.rawQuery(
        'SELECT COUNT(*) AS c FROM transactions WHERE ledgerId=?', [id]);
    return (r.first['c'] as int);
  }

  /* ---------------- 账户 ---------------- */
  Future<List<Account>> getAccounts() async {
    final d = await db;
    return (await d.query('accounts')).map(Account.fromMap).toList();
  }

  Future<int> insertAccount(Account a) async =>
      (await db).insert('accounts', a.toMap());

  Future<int> updateAccount(Account a) async => (await db)
      .update('accounts', a.toMap(), where: 'id=?', whereArgs: [a.id]);

  Future<int> deleteAccount(int id) async =>
      (await db).delete('accounts', where: 'id=?', whereArgs: [id]);

  Future<int> countTxnByAccount(int id) async {
    final d = await db;
    final r = await d.rawQuery(
        'SELECT COUNT(*) AS c FROM transactions WHERE accountId=?', [id]);
    return (r.first['c'] as int);
  }

  /// 该账户所有交易对余额的净贡献（收入 +，支出 -）
  Future<double> accountDelta(int accountId) async {
    final d = await db;
    final r = await d.rawQuery(
        "SELECT COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE -amount END),0) AS delta FROM transactions WHERE accountId=?",
        [accountId]);
    return (r.first['delta'] as num).toDouble();
  }

  /* ---------------- 分类 ---------------- */
  Future<List<Category>> getCategories() async {
    final d = await db;
    return (await d.query('categories')).map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category c) async =>
      (await db).insert('categories', c.toMap());

  Future<int> updateCategory(Category c) async => (await db)
      .update('categories', c.toMap(), where: 'id=?', whereArgs: [c.id]);

  Future<int> deleteCategory(int id) async =>
      (await db).delete('categories', where: 'id=?', whereArgs: [id]);

  Future<int> countTxnByCategory(int id) async {
    final d = await db;
    final r = await d.rawQuery(
        'SELECT COUNT(*) AS c FROM transactions WHERE categoryId=?', [id]);
    return (r.first['c'] as int);
  }

  /* ---------------- 交易 ---------------- */
  Future<List<Txn>> getTransactions(int ledgerId) async {
    final d = await db;
    final r = await d.query('transactions',
        where: 'ledgerId=?', whereArgs: [ledgerId], orderBy: 'date DESC');
    return r.map(Txn.fromMap).toList();
  }

  Future<List<Txn>> getTransactionsRange(
      int ledgerId, int from, int to, String type) async {
    final d = await db;
    final r = await d.query('transactions',
        where: 'ledgerId=? AND type=? AND date>=? AND date<=?',
        whereArgs: [ledgerId, type, from, to]);
    return r.map(Txn.fromMap).toList();
  }

  Future<int> insertTxn(Txn t) async =>
      (await db).insert('transactions', t.toMap());

  Future<int> updateTxn(Txn t) async => (await db)
      .update('transactions', t.toMap(), where: 'id=?', whereArgs: [t.id]);

  Future<int> deleteTxn(int id) async =>
      (await db).delete('transactions', where: 'id=?', whereArgs: [id]);
}
