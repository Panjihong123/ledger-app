import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'ledgers_page.dart';
import 'categories_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final current =
        p.ledgers.firstWhere((l) => l.id == p.currentLedgerId).name;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
          const SizedBox(height: 8),
          const Center(child: Text('记账软件', style: TextStyle(fontSize: 18))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('账本管理'),
            subtitle: Text('当前账本：$current'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LedgersPage())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('分类管理'),
            subtitle: const Text('管理支出 / 收入类型'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesPage())),
          ),
        ],
      ),
    );
  }
}
