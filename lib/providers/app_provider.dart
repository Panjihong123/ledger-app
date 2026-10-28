import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/ledger.dart';
import '../models/transaction.dart';

/// 全局状态：账本 / 账户 / 分类 / 交易，以及统计聚合
class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Ledger> ledgers = [];
  List<Account> accounts = [];
  List<Category> categories = [];
  int currentLedgerId = 1;
  bool _ready = false;

  bool get isReady => _ready;
  List<Category> get expenseCategories =>
      categories.where((c) => c.type == 'expense').toList();
  List<Category> get incomeCategories =>
      categories.where((c) => c.type == 'income').toList();

  Future<void> init() async {
    ledgers = await _db.getLedgers();
    currentLedgerId =
        (ledgers.firstWhere((l) => l.isDefault, orElse: () => ledgers.first))
            .id!;
    accounts = await _db.getAccounts();
    categories = await _db.getCategories();
    await _recalcAccountBalances();
    _ready = true;
    notifyListeners();
  }

  Future<void> _recalcAccountBalances() async {
    for (final a in accounts) {
      final delta = await _db.accountDelta(a.id!);
      a.currentBalance = a.initialBalance + delta;
    }
  }

  double get totalAssets =>
      accounts.fold(0, (s, a) => s + (a.currentBalance ?? a.initialBalance));

  /* ---------------- 账本 ---------------- */
  Future<void> addLedger(String name) async {
    final id = await _db.insertLedger(Ledger(name: name));
    ledgers.add(Ledger(id: id, name: name));
    notifyListeners();
  }

  Future<bool> deleteLedger(int id) async {
    if (ledgers.length <= 1) return false; // 至少保留一个
    if (await _db.countTxnByLedger(id) > 0) return false; // 有交易不可删
    await _db.deleteLedger(id);
    ledgers.removeWhere((x) => x.id == id);
    if (currentLedgerId == id) currentLedgerId = ledgers.first.id!;
    notifyListeners();
    return true;
  }

  void setCurrentLedger(int id) {
    currentLedgerId = id;
    notifyListeners();
  }

  /* ---------------- 账户 ---------------- */
  Future<void> addAccount(Account a) async {
    final id = await _db.insertAccount(a);
    a.id = id;
    a.currentBalance = a.initialBalance;
    accounts.add(a);
    notifyListeners();
  }

  Future<void> updateAccount(Account a) async {
    await _db.updateAccount(a);
    final i = accounts.indexWhere((x) => x.id == a.id);
    if (i >= 0) accounts[i] = a;
    await _recalcAccountBalances();
    notifyListeners();
  }

  /// 直接把账户余额调整为 newBalance
  Future<void> adjustAccountBalance(int id, double newBalance) async {
    final a = accounts.firstWhere((x) => x.id == id);
    final delta = await _db.accountDelta(id);
    a.initialBalance = newBalance - delta;
    await _db.updateAccount(a);
    await _recalcAccountBalances();
    notifyListeners();
  }

  Future<bool> deleteAccount(int id) async {
    if (await _db.countTxnByAccount(id) > 0) return false; // 有交易不可删
    await _db.deleteAccount(id);
    accounts.removeWhere((x) => x.id == id);
    notifyListeners();
    return true;
  }

  /* ---------------- 分类 ---------------- */
  Future<void> addCategory(Category c) async {
    final id = await _db.insertCategory(c);
    c.id = id;
    categories.add(c);
    notifyListeners();
  }

  Future<void> updateCategory(Category c) async {
    await _db.updateCategory(c);
    final i = categories.indexWhere((x) => x.id == c.id);
    if (i >= 0) categories[i] = c;
    notifyListeners();
  }

  Future<bool> deleteCategory(int id) async {
    if (await _db.countTxnByCategory(id) > 0) return false; // 有交易不可删
    await _db.deleteCategory(id);
    categories.removeWhere((x) => x.id == id);
    notifyListeners();
    return true;
  }

  /* ---------------- 交易 ---------------- */
  Future<void> addTransaction(Txn t) async {
    await _db.insertTxn(t);
    await _recalcAccountBalances();
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTxn(id);
    await _recalcAccountBalances();
    notifyListeners();
  }

  Future<List<Txn>> transactionsOfCurrentLedger() =>
      _db.getTransactions(currentLedgerId);

  /* ---------------- 统计 ---------------- */
  Future<Map<String, double>> monthSummary() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final to = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1))
        .millisecondsSinceEpoch;
    final e = await _db.getTransactionsRange(currentLedgerId, from, to, 'expense');
    final i = await _db.getTransactionsRange(currentLedgerId, from, to, 'income');
    return {
      'expense': e.fold(0.0, (s, t) => s + t.amount),
      'income': i.fold(0.0, (s, t) => s + t.amount),
    };
  }

  /// 按分类聚合（type: expense/income；from/to 为毫秒区间）
  Future<List<CategoryStat>> statsByCategory(
      String type, int from, int to) async {
    final txs =
        await _db.getTransactionsRange(currentLedgerId, from, to, type);
    final map = <int, double>{};
    for (final t in txs) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    final list = <CategoryStat>[];
    map.forEach((cid, sum) {
      final cat = categories.firstWhere((c) => c.id == cid,
          orElse: () => Category(id: cid, name: '未分类', type: type));
      list.add(CategoryStat(cat, sum));
    });
    list.sort((a, b) => b.sum.compareTo(a.sum));
    return list;
  }
}

class CategoryStat {
  final Category category;
  final double sum;
  CategoryStat(this.category, this.sum);
}
