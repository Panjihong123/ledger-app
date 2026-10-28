import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_page.dart';
import 'screens/accounts_page.dart';
import 'screens/statistics_page.dart';
import 'screens/profile_page.dart';
import 'screens/transaction_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => AppProvider()..init(),
        child: MaterialApp(
          title: '记账软件',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.light,
          ),
          home: const RootPage(),
        ),
      );
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _idx = 0;
  final _pages = const [
    HomePage(),
    AccountsPage(),
    StatisticsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_idx],
        floatingActionButton: _idx == 0
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransactionPage()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('记一笔'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: '首页'),
            NavigationDestination(
                icon: Icon(Icons.account_balance_wallet), label: '账户'),
            NavigationDestination(icon: Icon(Icons.pie_chart), label: '统计'),
            NavigationDestination(icon: Icon(Icons.person), label: '我的'),
          ],
        ),
      );
}
