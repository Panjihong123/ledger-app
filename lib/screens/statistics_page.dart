import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';

/// 统计饼图配色（按索引取，保证每片颜色不同）
const _palette = [
  Color(0xFFEF5350),
  Color(0xFFAB47BC),
  Color(0xFF5C6BC0),
  Color(0xFF29B6F6),
  Color(0xFF26C6DA),
  Color(0xFF26A69A),
  Color(0xFF66BB6A),
  Color(0xFF9CCC65),
  Color(0xFFD4E157),
  Color(0xFFFFCA28),
  Color(0xFFFFA726),
  Color(0xFFEC407A),
  Color(0xFF8D6E63),
  Color(0xFF78909C),
  Color(0xFF7E57C2),
  Color(0xFF42A5F5),
];

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _range = 'month'; // month / year
  String _type = 'expense'; // expense / income
  bool _byTop = true; // true=按一级分类；false=按二级分类
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
        future: p.statsByCategory(_type, from, to, byTop: _byTop),
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
              // 一级/二级维度切换
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('按一级')),
                  ButtonSegment(value: false, label: Text('按二级')),
                ],
                selected: {_byTop},
                onSelectionChanged: (s) => setState(() => _byTop = s.first),
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
                  height: 170,
                  child: PieChart(
                    PieChartData(
                      sections: stats.asMap().entries.map((e) {
                        final s = e.value;
                        final idx = e.key;
                        return PieChartSectionData(
                          value: s.sum,
                          title: '${(s.sum / total * 100).toStringAsFixed(0)}%',
                          color: _palette[idx % _palette.length],
                          radius: 64,
                          titleStyle: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
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
                    leading: CircleAvatar(
                      backgroundColor: _palette[idx % _palette.length],
                      child: Text(s.category.icon,
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(s.category.name),
                    subtitle: LinearProgressIndicator(
                      value: pct,
                      color: _palette[idx % _palette.length],
                    ),
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
