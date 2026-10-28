import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _range = 'month'; // month / year
  String _type = 'expense'; // expense / income
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final from = _range == 'month'
        ? DateTime(_year, _month, 1).millisecondsSinceEpoch
        : DateTime(_year, 1, 1).millisecondsSinceEpoch;
    final to = _range == 'month'
        ? DateTime(_year, _month + 1, 1)
            .subtract(const Duration(milliseconds: 1))
            .millisecondsSinceEpoch
        : DateTime(_year + 1, 1, 1)
            .subtract(const Duration(milliseconds: 1))
            .millisecondsSinceEpoch;

    final title = _range == 'month' ? '$_year 年 $_month 月' : '$_year 年';

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: FutureBuilder<List<CategoryStat>>(
        future: p.statsByCategory(_type, from, to),
        builder: (ctx, snap) {
          final stats = snap.data ?? [];
          final total = stats.fold(0.0, (s, e) => s + e.sum);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 范围切换
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'month', label: Text('按月')),
                  ButtonSegment(value: 'year', label: Text('按年')),
                ],
                selected: {_range},
                onSelectionChanged: (s) => setState(() => _range = s.first),
              ),
              const SizedBox(height: 12),
              // 收/支切换
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('支出')),
                  ButtonSegment(value: 'income', label: Text('收入')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
              // 年/月选择
              Row(
                children: [
                  DropdownButton<int>(
                    value: _year,
                    items: List.generate(11, (i) => DateTime.now().year - 5 + i)
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y 年')))
                        .toList(),
                    onChanged: (v) => setState(() => _year = v!),
                  ),
                  if (_range == 'month') ...[
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _month,
                      items: List.generate(12, (i) => i + 1)
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text('$m 月')))
                          .toList(),
                      onChanged: (v) => setState(() => _month = v!),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text('$title ${_type == 'expense' ? '支出' : '收入'}合计：${money(total)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (stats.isEmpty)
                const SizedBox(
                    height: 200,
                    child: Center(child: Text('该区间暂无记录')))
              else ...[
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: stats
                          .map((s) => PieChartSectionData(
                                value: s.sum,
                                title:
                                    '${(s.sum / total * 100).toStringAsFixed(0)}%',
                                color: Color(s.category.color),
                                radius: 90,
                                titleStyle: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ))
                          .toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('排行', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...stats.asMap().entries.map((e) {
                  final idx = e.key;
                  final s = e.value;
                  final pct = total > 0 ? s.sum / total : 0.0;
                  return ListTile(
                    leading: CircleAvatar(child: Text(s.category.icon)),
                    title: Text(s.category.name),
                    subtitle: LinearProgressIndicator(value: pct),
                    trailing: Text(money(s.sum)),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}
