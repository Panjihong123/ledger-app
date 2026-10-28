import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';

class CategoryEditPage extends StatelessWidget {
  final Category? category;
  final String type; // 新建时的默认类型
  const CategoryEditPage({super.key, this.category, this.type = 'expense'});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    final isEdit = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final iconCtrl = TextEditingController(text: category?.icon ?? '📦');
    String t = category?.type ?? type;
    int color = category?.color ?? 0xFF42A5F5;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑分类' : '添加分类')),
      body: StatefulBuilder(
        builder: (context, setState) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('支出')),
                ButtonSegment(value: 'income', label: Text('收入')),
              ],
              selected: {t},
              onSelectionChanged: (s) => setState(() => t = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '分类名称'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: iconCtrl,
              decoration: const InputDecoration(
                  labelText: '图标（emoji）', hintText: '例如 🍚 🚌 💡'),
            ),
            const SizedBox(height: 16),
            const Text('颜色'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                0xFFEF5350, 0xFFEC407A, 0xFFAB47BC, 0xFF42A5F5,
                0xFF26A69A, 0xFF66BB6A, 0xFF26C6DA, 0xFF78909C,
              ].map((c) => GestureDetector(
                    onTap: () => setState(() => color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: color == c
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('请填写分类名称')));
                  return;
                }
                final c = Category(
                  id: category?.id,
                  name: name,
                  type: t,
                  color: color,
                  icon: iconCtrl.text.trim().isEmpty
                      ? '📦'
                      : iconCtrl.text.trim(),
                );
                if (isEdit) {
                  p.updateCategory(c);
                } else {
                  p.addCategory(c);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }
}
