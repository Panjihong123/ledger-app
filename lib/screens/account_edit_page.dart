import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';

class AccountEditPage extends StatelessWidget {
  final Account? account;
  const AccountEditPage({super.key, this.account});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    final nameCtrl = TextEditingController(text: account?.name ?? '');
    final balanceCtrl = TextEditingController(
        text: (account?.initialBalance ?? 0).toStringAsFixed(2));
    String type = account?.type ?? 'cash';

    return Scaffold(
      appBar: AppBar(title: Text(account == null ? '添加账户' : '编辑账户')),
      body: StatefulBuilder(
        builder: (context, setState) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '账户名称'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: '账户类型'),
              items: accountTypeMeta.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value['label'] as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => type = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                  labelText: '初始余额', prefixText: '¥'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final bal = double.tryParse(balanceCtrl.text) ?? 0;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('请填写账户名称')));
                  return;
                }
                final a = Account(
                    id: account?.id,
                    name: name,
                    type: type,
                    initialBalance: bal);
                if (account == null) {
                  p.addAccount(a);
                } else {
                  p.updateAccount(a);
                }
                Navigator.pop(context);
              },
              child: Text(account == null ? '添加' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}
