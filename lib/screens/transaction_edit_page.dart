import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';

/// 编辑一条已有的交易记录
class TransactionEditPage extends StatefulWidget {
  final Txn txn;
  const TransactionEditPage({super.key, required this.txn});

  @override
  State<TransactionEditPage> createState() => _TransactionEditPageState();
}

class _TransactionEditPageState extends State<TransactionEditPage> {
  late String _type;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late int? _accountId;
  late int? _categoryId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final t = widget.txn;
    _type = t.type;
    _amountCtrl.text = t.amount.toStringAsFixed(2);
    _noteCtrl.text = t.note ?? '';
    _accountId = t.accountId;
    _categoryId = t.categoryId;
    _date = DateTime.fromMillisecondsSinceEpoch(t.date);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cats = _type == 'expense' ? p.expenseCategories : p.incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: '删除',
            onPressed: () => _delete(p),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('支出')),
              ButtonSegment(value: 'income', label: Text('收入')),
            ],
            selected: {_type},
            onSelectionChanged: (s) {
              setState(() {
                _type = s.first;
                _categoryId = (_type == 'expense'
                        ? p.expenseCategories
                        : p.incomeCategories)
                    .isNotEmpty
                    ? (_type == 'expense'
                            ? p.expenseCategories
                            : p.incomeCategories)
                        .first
                        .id
                    : null;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: '金额', prefixText: '¥', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _accountId,
            decoration: const InputDecoration(labelText: '账户'),
            items: p.accounts
                .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                .toList(),
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _categoryId,
            decoration: const InputDecoration(labelText: '分类'),
            items: cats
                .map((c) => DropdownMenuItem(
                    value: c.id, child: Text('${c.icon} ${c.name}')))
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('日期'),
            trailing: Text(ymd(_date.millisecondsSinceEpoch)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: '备注（可选）'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _save(p),
            child: const Text('保存修改'),
          ),
        ],
      ),
    );
  }

  void _save(AppProvider p) {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入正确的金额')));
      return;
    }
    if (_accountId == null || _categoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择账户和分类')));
      return;
    }
    p.updateTransaction(Txn(
      id: widget.txn.id,
      ledgerId: widget.txn.ledgerId,
      accountId: _accountId!,
      categoryId: _categoryId!,
      type: _type,
      amount: amount,
      date: _date.millisecondsSinceEpoch,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }

  void _delete(AppProvider p) {
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
              p.deleteTransaction(widget.txn.id!);
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 关闭编辑页
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
