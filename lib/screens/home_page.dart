import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';
import 'transaction_edit_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ledgerName =
        p.ledgers.firstWhere((l) => l.id == p.currentLedgerId).name;

    return Scaffold(
      appBar: AppBar(
        title: Text('当前账本：$ledgerName'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => p.init(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 总资产
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('总资产', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(money(p.totalAssets),
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 本月收支
            FutureBuilder<Map<String, double>>(
              future: p.monthSummary(),
              builder: (c, snap) {
                final e = snap.data?['expense'] ?? 0;
                final i = snap.data?['income'] ?? 0;
                return Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                          label: '本月支出', value: e, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                          label: '本月收入', value: i, color: Colors.green),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('账单明细'),
              subtitle: const Text('查看 / 编辑当前账本全部记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRecords(context, p),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecords(BuildContext context, AppProvider p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecordsSheet(p: p),
    );
  }
}

/// 账单明细面板：可点击编辑、可删除
class _RecordsSheet extends StatefulWidget {
  final AppProvider p;
  const _RecordsSheet({required this.p});

  @override
  State<_RecordsSheet> createState() => _RecordsSheetState();
}

class _RecordsSheetState extends State<_RecordsSheet> {
  List<Txn> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _list = await widget.p.transactionsOfCurrentLedger();
    if (mounted) setState(() => _loading = false);
  }

  Category _catOf(int id) => widget.p.categories.firstWhere(
      (c) => c.id == id,
      orElse: () => Category(id: id, name: '未分类', type: 'expense',
          color: 0xFF9E9E9E, icon: '📦'));

  Account _accOf(int id) => widget.p.accounts.firstWhere(
      (x) => x.id == id,
      orElse: () => Account(name: '账户', type: 'other'));

  void _edit(Txn t) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionEditPage(txn: t)),
    );
  }

  void _confirmDelete(Txn t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除该记录'),
        content: const Text('确定要删除这笔记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(
            onPressed: () {
              widget.p.deleteTransaction(t.id!);
              Navigator.pop(context);
              _load();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          height: 300, child: Center(child: CircularProgressIndicator()));
    }
    if (_list.isEmpty) {
      return const SizedBox(
          height: 300, child: Center(child: Text('暂无记账记录')));
    }
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: ListView.separated(
        itemCount: _list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final t = _list[i];
          final cat = _catOf(t.categoryId);
          final top = cat.parentId != null ? _catOf(cat.parentId!) : null;
          final acc = _accOf(t.accountId);
          final isExp = t.type == 'expense';
          final title = top == null ? cat.name : '${top.name}·${cat.name}';
          return ListTile(
            leading: Text(cat.icon, style: const TextStyle(fontSize: 22)),
            title: Text(title),
            subtitle: Text('${acc.name} · ${ymd(t.date)}'
                '${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isExp ? '-' : '+'}${money(t.amount)}',
                  style: TextStyle(
                      color: isExp ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(t),
                ),
              ],
            ),
            onTap: () => _edit(t),
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 6),
              Text(money(value),
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      );
}
