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
          _CategoryList(list: p.expenseCategories),
          _CategoryList(list: p.incomeCategories),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<Category> list;
  const _CategoryList({required this.list});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context, listen: false);
    if (list.isEmpty) {
      return const Center(child: Text('暂无分类，点击 + 添加'));
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final c = list[i];
        return ListTile(
          leading: CircleAvatar(
              backgroundColor: Color(c.color).withOpacity(0.2),
              child: Text(c.icon)),
          title: Text(c.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CategoryEditPage(category: c)),
          ),
          onLongPress: () async {
            final ok = await p.deleteCategory(c.id!);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('该分类已有交易记录，无法删除')));
            }
          },
        );
      },
    );
  }
}
