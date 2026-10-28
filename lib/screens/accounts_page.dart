import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';
import 'account_edit_page.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('资产管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountEditPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              title: const Text('账户总余额',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              trailing: Text(money(p.totalAssets),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ),
          ),
          const SizedBox(height: 8),
          ...p.accounts.map((a) => _AccountCard(account: a)),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context, listen: false);
    final meta = accountTypeMeta[account.type]!;
    final balance = account.currentBalance ?? account.initialBalance;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(meta['icon'] as IconData, color: Colors.blue),
        ),
        title: Text(account.name),
        subtitle: Text(meta['label'] as String),
        trailing: Text(money(balance),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: balance < 0 ? Colors.red : Colors.black87)),
        onTap: () => _showActions(context, p, account),
      ),
    );
  }

  void _showActions(BuildContext context, AppProvider p, Account a) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑名称 / 类型'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AccountEditPage(account: a)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.adjust),
              title: const Text('调整余额'),
              onTap: () {
                Navigator.pop(context);
                _adjustBalance(context, p, a);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除账户', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await p.deleteAccount(a.id!);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('该账户已有交易记录，无法删除')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _adjustBalance(BuildContext context, AppProvider p, Account a) {
    final ctrl = TextEditingController(
        text: (a.currentBalance ?? a.initialBalance).toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('调整「${a.name}」余额'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: const InputDecoration(labelText: '新余额', prefixText: '¥'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v == null) return;
              p.adjustAccountBalance(a.id!, v);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
