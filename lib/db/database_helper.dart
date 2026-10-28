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
    return openDatabase(path,
        version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
        'CREATE TABLE ledgers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, isDefault INTEGER)');
    await db.execute(
        'CREATE TABLE accounts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, initialBalance REAL)');
    await db.execute(
        'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, color INTEGER, icon TEXT, parentId INTEGER)');
    await db.execute(
        'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, ledgerId INTEGER, accountId INTEGER, categoryId INTEGER, type TEXT, amount REAL, date INTEGER, note TEXT)');

    await db.insert('ledgers', {'name': '默认账本', 'isDefault': 1});
    await _seedCategories(db);
    await db.insert('accounts',
        {'name': '现金', 'type': 'cash', 'initialBalance': 0});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE categories ADD COLUMN parentId INTEGER');
      // 用新的人群完整分类树替换旧的扁平默认分类
      await db.delete('categories');
      await _seedCategories(db);
    }
  }

  /// 预置支出/收入的两级分类
  Future<void> _seedCategories(Database db) async {
    // 支出分类树：一级 -> [二级...]
    const expenseTree = {
      '运动': [
        '羽毛球订场', '羽毛球穿线', '羽毛球接龙', '羽毛球拍', '羽毛球鞋'
      ],
      '房子': ['房租', '水费', '电费', '燃气费'],
      '车子': [
        '加油', '停车', '租房停车月卡', '公司停车月卡', '保养', '玻璃水',
        '保险', '违章'
      ],
      '伟': ['伟生活费'],
      '餐饮': ['堂食', '外卖', '红妹外卖', '零食', '矿泉水', '水果'],
      '减肥计划': ['减肥奖励'],
      '电话费': ['182', '191', '网费'],
      '数码产品': ['买手机', '买电脑'],
      '日用': [
        '洗发水', '沐浴露', '洗衣粉', '牙膏', '牙刷', '剃须刀', '身体乳',
        '理发', '衣服', '鞋子', '袜子', '纸巾'
      ],
      '会员': ['哔哩哔哩', '优酷', '爱奇艺', '苹果音乐', '网易云音乐'],
    };
    const incomeTree = {
      '工资': ['月度工资', '十三薪', '公积金', '年终奖', '劳务'],
      '还钱': ['叶军', '红妹'],
      '运动收入': ['订场A钱'],
      '小额': ['微信红包', '评价返现', '番茄小说'],
      '结息': ['朝朝宝', '微信零钱通', '公积金结息'],
    };

    const expIcons = {
      '运动': '🏸', '房子': '🏠', '车子': '🚗', '伟': '🧑',
      '餐饮': '🍚', '减肥计划': '🏃', '电话费': '📞',
      '数码产品': '💻', '日用': '🧴', '会员': '🎬',
    };
    const incIcons = {
      '工资': '💰', '还钱': '💸', '运动收入': '🏸',
      '小额': '🧧', '结息': '📈',
    };
    const expColors = {
      '运动': 0xFF26C6DA, '房子': 0xFFAB47BC, '车子': 0xFF42A5F5,
      '伟': 0xFFEF5350, '餐饮': 0xFF66BB6A, '减肥计划': 0xFFEC407A,
      '电话费': 0xFF26A69A, '数码产品': 0xFF78909C, '日用': 0xFF8D6E63,
      '会员': 0xFF5C6BC0,
    };
    const incColors = {
      '工资': 0xFF42A5F5, '还钱': 0xFFEF5350, '运动收入': 0xFF26C6DA,
      '小额': 0xFFEC407A, '结息': 0xFF66BB6A,
    };

    for (final entry in expenseTree.entries) {
      final topId = await db.insert('categories', {
        'name': entry.key,
        'type': 'expense',
        'color': expColors[entry.key] ?? 0xFF9E9E9E,
        'icon': expIcons[entry.key] ?? '📦',
        'parentId': null,
      });
      for (final child in entry.value) {
        await db.insert('categories', {
          'name': child,
          'type': 'expense',
          'color': expColors[entry.key] ?? 0xFF9E9E9E,
          'icon': expIcons[entry.key] ?? '📦',
          'parentId': topId,
        });
      }
    }
    for (final entry in incomeTree.entries) {
      final topId = await db.insert('categories', {
        'name': entry.key,
        'type': 'income',
        'color': incColors[entry.key] ?? 0xFF9E9E9E,
        'icon': incIcons[entry.key] ?? '📦',
        'parentId': null,
      });
      for (final child in entry.value) {
        await db.insert('categories', {
          'name': child,
          'type': 'income',
          'color': incColors[entry.key] ?? 0xFF9E9E9E,
          'icon': incIcons[entry.key] ?? '📦',
          'parentId': topId,
        });
      }
    }
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
