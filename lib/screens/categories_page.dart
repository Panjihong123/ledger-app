import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';
import 'category_edit_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '支出'), Tab(text: '收入')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryEditPage(
                type: _tabController.index == 1 ? 'income' : 'expense'),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryTree(p: p, type: 'expense'),
          _CategoryTree(p: p, type: 'income'),
        ],
      ),
    );
  }
}

class _CategoryTree extends StatelessWidget {
  final AppProvider p;
  final String type;
  const _CategoryTree({required this.p, required this.type});

  @override
  Widget build(BuildContext context) {
    final tops = p.topCategories(type);
    if (tops.isEmpty) {
      return const Center(child: Text('暂无分类，点击 + 添加'));
    }
    return ListView.separated(
      itemCount: tops.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final top = tops[i];
        final children = p.subCategories(top.id!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: Color(top.color).withOpacity(0.2),
                  child: Text(top.icon)),
              title: Text(top.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CategoryEditPage(category: top)),
              ),
              onLongPress: () => _delete(context, top),
            ),
            ...children.map((c) => ListTile(
                  contentPadding:
                      const EdgeInsets.only(left: 56, right: 16, top: 0, bottom: 0),
                  leading: CircleAvatar(
                      backgroundColor: Color(c.color).withOpacity(0.2),
                      child: Text(c.icon)),
                  title: Text(c.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CategoryEditPage(category: c)),
                  ),
                  onLongPress: () => _delete(context, c),
                )),
          ],
        );
      },
    );
  }

  void _delete(BuildContext context, Category c) async {
    final ok = await p.deleteCategory(c.id!);
    if (!ok && context.mounted) {
      final hasChild = c.parentId == null && p.subCategories(c.id!).isNotEmpty;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hasChild
              ? '请先删除该分类下的二级分类'
              : '该分类已有交易记录，无法删除')));
    }
  }
}
