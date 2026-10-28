import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';
import 'transaction_page.dart';
import 'accounts_page.dart';
import 'statistics_page.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: '统计',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsPage())),
          ),
        ],
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
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('资产管理'),
              subtitle: const Text('添加 / 删除账户，调整余额'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountsPage())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('账单明细'),
              subtitle: const Text('查看当前账本全部记录'),
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
      builder: (_) => FutureBuilder(
        future: p.transactionsOfCurrentLedger(),
        builder: (c, snap) {
          if (!snap.hasData) {
            return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()));
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const SizedBox(
                height: 200,
                child: Center(child: Text('暂无记账记录')));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = list[i];
              final cat = p.categories.firstWhere(
                  (x) => x.id == t.categoryId,
                  orElse: () => p.categories.first);
              final acc = p.accounts.firstWhere((x) => x.id == t.accountId,
                  orElse: () => Account(name: '账户', type: 'other'));
              final isExp = t.type == 'expense';
              return ListTile(
                leading: Text(cat.icon, style: const TextStyle(fontSize: 22)),
                title: Text(cat.name),
                subtitle: Text('${acc.name} · ${ymd(t.date)}'
                    '${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}'),
                trailing: Text(
                  '${isExp ? '-' : '+'}${money(t.amount)}',
                  style: TextStyle(
                      color: isExp ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold),
                ),
              );
            },
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
