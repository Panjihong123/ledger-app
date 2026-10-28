import 'package:flutter/material.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';

/// 打开「两级分类」选择面板。
/// 结构：一级分类分组 → 展开后显示其下二级分类；
/// 一级分类若没有二级分类，则一级本身可直接选中。
/// 返回用户选中的分类，取消返回 null。
Future<Category?> showCategoryPicker(
  BuildContext context, {
  required AppProvider provider,
  required String type, // expense / income
  int? selectedId,
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CategoryPickerSheet(
      provider: provider,
      type: type,
      selectedId: selectedId,
    ),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  final AppProvider provider;
  final String type;
  final int? selectedId;

  const _CategoryPickerSheet({
    required this.provider,
    required this.type,
    this.selectedId,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  List<Category> _tops = [];
  int? _expandedId;

  @override
  void initState() {
    super.initState();
    _tops = widget.provider.topCategories(widget.type);
    // 默认展开「当前选中分类」所属的一级分类，方便直接看到它
    final sel = widget.provider.categoryById(widget.selectedId);
    if (sel != null) {
      _expandedId = sel.parentId ?? sel.id;
    } else if (_tops.isNotEmpty) {
      _expandedId = _tops.first.id; // 没有选中过则默认展开第一个大类
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Text(
                  widget.type == 'expense' ? '选择支出分类' : '选择收入分类',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: _tops.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('还没有分类，请先到「分类管理」添加'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _tops.length,
                    itemBuilder: (_, i) => _buildTopTile(_tops[i], theme),
                  ),
          ),
        ],
      ),
    );
  }

  /// 一个一级分类：标题行 + 展开后的二级分类
  Widget _buildTopTile(Category top, ThemeData theme) {
    final subs = widget.provider.subCategories(top.id!);
    final expanded = _expandedId == top.id;
    final topSelected = widget.selectedId == top.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Text(top.icon, style: const TextStyle(fontSize: 20)),
          title: Text(
            top.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  expanded ? FontWeight.w600 : FontWeight.normal,
              color: expanded ? theme.colorScheme.primary : null,
            ),
          ),
          // 无二级分类 → 显示「可直接选」的勾；有二级 → 显示展开箭头
          trailing: subs.isEmpty
              ? (topSelected
                  ? Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 20)
                  : null)
              : Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey,
                ),
          onTap: () {
            if (subs.isEmpty) {
              Navigator.pop(context, top);
            } else {
              setState(() => _expandedId = expanded ? null : top.id);
            }
          },
        ),
        if (expanded && subs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in subs)
                  ChoiceChip(
                    label: Text('${s.icon} ${s.name}',
                        style: const TextStyle(fontSize: 13)),
                    selected: widget.selectedId == s.id,
                    onSelected: (_) => Navigator.pop(context, s),
                  ),
              ],
            ),
          ),
        const Divider(height: 1, indent: 20),
      ],
    );
  }
}
