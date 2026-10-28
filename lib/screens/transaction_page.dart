import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';
import '../widgets/category_picker.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _type = 'expense'; // expense / income
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int? _accountId;
  int? _categoryId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    _accountId = p.accounts.isNotEmpty ? p.accounts.first.id : null;
    _categoryId = p.defaultCategory('expense')?.id;
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 兼容：categories 未就绪时补一个默认分类，避免选择框空着
    if (_categoryId == null && p.isReady) {
      _categoryId = p.defaultCategory(_type)?.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 收/支切换
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('支出')),
              ButtonSegment(value: 'income', label: Text('收入')),
            ],
            selected: {_type},
            onSelectionChanged: (s) {
              setState(() {
                _type = s.first;
                // 切换收支后重置为该类型的默认分类
                _categoryId = p.defaultCategory(_type)?.id;
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
          // 账户
          DropdownButtonFormField<int>(
            value: _accountId,
            decoration: const InputDecoration(labelText: '账户'),
            items: p.accounts
                .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                .toList(),
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 16),
          // 分类：点开面板，按一级分类分组选二级分类（新增的也会归在所属大类下）
          InkWell(
            onTap: () async {
              final picked = await showCategoryPicker(
                context,
                provider: p,
                type: _type,
                selectedId: _categoryId,
              );
              if (picked != null && mounted) {
                setState(() => _categoryId = picked.id);
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _categoryId == null ? '请选择分类' : p.categoryLabel(_categoryId!),
                style: TextStyle(
                  fontSize: 15,
                  color: _categoryId == null ? Colors.grey[600] : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 日期
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
            child: const Text('保存'),
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
    p.addTransaction(Txn(
      ledgerId: p.currentLedgerId,
      accountId: _accountId!,
      categoryId: _categoryId!,
      type: _type,
      amount: amount,
      date: _date.millisecondsSinceEpoch,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }
}
