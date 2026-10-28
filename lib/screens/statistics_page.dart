import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/format.dart';
import '../utils/palette.dart';

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

  /// 单个饼图切片：颜色按下标从调色板取，保证相邻/不同分类颜色不同；
  /// 占比小于 5% 的切片不画百分比文字，避免小切片文字挤压重叠
  PieChartSectionData _buildSection(
      CategoryStat s, int index, double total) {
    final pct = total > 0 ? s.sum / total : 0.0;
    return PieChartSectionData(
      value: s.sum,
      color: chartColorAt(index),
      radius: 58,
      title: pct >= 0.05 ? '${(pct * 100).toStringAsFixed(0)}%' : '',
      titlePositionPercentageOffset: 0.55,
      titleStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

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
                // 饼图：控制尺寸，避免占满整屏
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 1.5,
                      centerSpaceRadius: 34,
                      sections: [
                        for (var i = 0; i < stats.length; i++)
                          _buildSection(stats[i], i, total),
                      ],
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
                  final c = chartColorAt(idx);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        // 分类色块：与饼图颜色一一对应
                        Container(
                          width: 10,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(s.category.icon,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.category.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '${(pct * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    money(s.sum),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 4,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(c),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
