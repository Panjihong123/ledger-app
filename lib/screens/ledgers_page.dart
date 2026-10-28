import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ledger.dart';
import '../providers/app_provider.dart';

class LedgersPage extends StatelessWidget {
  const LedgersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('账本管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addLedger(context, p),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: p.ledgers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final l = p.ledgers[i];
          final isCurrent = l.id == p.currentLedgerId;
          return ListTile(
            leading: const Icon(Icons.book),
            title: Text(l.name),
            trailing: isCurrent
                ? const Chip(label: Text('当前'), backgroundColor: Colors.blue)
                : const Icon(Icons.chevron_right),
            onTap: isCurrent
                ? null
                : () {
                    p.setCurrentLedger(l.id!);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('已切换到「${l.name}」')));
                  },
            onLongPress: () => _deleteLedger(context, p, l),
          );
        },
      ),
    );
  }

  void _addLedger(BuildContext context, AppProvider p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新建账本'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: '账本名称'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) p.addLedger(name);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _deleteLedger(BuildContext context, AppProvider p, Ledger l) async {
    if (p.ledgers.length <= 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('至少保留一个账本')));
      return;
    }
    final ok = await p.deleteLedger(l.id!);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('该账本已有交易记录，无法删除')));
    }
  }
}
