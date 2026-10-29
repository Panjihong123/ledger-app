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
  // 按日统计选中的那一天（默认今天）
  DateTime _day = DateTime.now();
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

  /// 切换按日统计的日期（同时同步年/月，切到按月时衔接自然）
  void _changeDay(DateTime d) {
    setState(() {
      _day = d;
      _year = d.year;
      _month = d.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (!p.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 统计偏好存在 provider（写库），这里直接读，切换时回写
    final range = p.statRange; // day / month / year
    final type = p.statType; // expense / income
    final byTop = p.statByTop;

    // 时间区间
    final int from;
    final int to;
    final String title;
    if (range == 'day') {
      final start = DateTime(_day.year, _day.month, _day.day);
      from = start.millisecondsSinceEpoch;
      to = start
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1))
          .millisecondsSinceEpoch;
      title = '${_day.year} 年 ${_day.month} 月 ${_day.day} 日';
    } else if (range == 'month') {
      from = DateTime(_year, _month, 1).millisecondsSinceEpoch;
      to = DateTime(_year, _month + 1, 1)
          .subtract(const Duration(milliseconds: 1))
          .millisecondsSinceEpoch;
      title = '$_year 年 $_month 月';
    } else {
      from = DateTime(_year, 1, 1).millisecondsSinceEpoch;
      to = DateTime(_year + 1, 1, 1)
          .subtract(const Duration(milliseconds: 1))
          .millisecondsSinceEpoch;
      title = '$_year 年';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: FutureBuilder<List<CategoryStat>>(
        future: p.statsByCategory(type, from, to, byTop: byTop),
        builder: (ctx, snap) {
          final stats = snap.data ?? [];
          final total = stats.fold(0.0, (s, e) => s + e.sum);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 统计粒度：按日 / 按月 / 按年
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'day', label: Text('按日')),
                  ButtonSegment(value: 'month', label: Text('按月')),
                  ButtonSegment(value: 'year', label: Text('按年')),
                ],
                selected: {range},
                onSelectionChanged: (s) => p.setStatRange(s.first),
              ),
              const SizedBox(height: 12),
              // 收/支切换
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('支出')),
                  ButtonSegment(value: 'income', label: Text('收入')),
                ],
                selected: {type},
                onSelectionChanged: (s) => p.setStatType(s.first),
              ),
              const SizedBox(height: 12),
              // 一级/二级维度切换
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('按一级')),
                  ButtonSegment(value: false, label: Text('按二级')),
                ],
                selected: {byTop},
                onSelectionChanged: (s) => p.setStatByTop(s.first),
              ),
              const SizedBox(height: 12),
              // 时间选择：按日 → 日期（可前后翻页）；按月/按年 → 年（月）下拉
              if (range == 'day')
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: '前一天',
                      onPressed: () => _changeDay(
                          _day.subtract(const Duration(days: 1))),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(ymd(_day.millisecondsSinceEpoch)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _day,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            _changeDay(picked);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: '后一天',
                      onPressed: () =>
                          _changeDay(_day.add(const Duration(days: 1))),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    DropdownButton<int>(
                      value: _year,
                      items: List.generate(
                              11, (i) => DateTime.now().year - 5 + i)
                          .map((y) =>
                              DropdownMenuItem(value: y, child: Text('$y 年')))
                          .toList(),
                      onChanged: (v) => setState(() => _year = v!),
                    ),
                    if (range == 'month') ...[
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
              Text(
                  '$title ${type == 'expense' ? '支出' : '收入'}合计：${money(total)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (stats.isEmpty)
                SizedBox(
                    height: 200,
                    child: Center(
                        child: Text(range == 'day'
                            ? '这一天还没有记录'
                            : '该区间暂无记录')))
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
