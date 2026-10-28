import 'package:flutter/material.dart';

/// 统计图表专用调色板
/// 相邻色相差异明显，保证饼图每个分类颜色不同；超出长度后循环使用
const List<Color> kChartPalette = <Color>[
  Color(0xFF4C8DFF), // 蓝
  Color(0xFFFF6B6B), // 珊瑚红
  Color(0xFF2EC4B6), // 青绿
  Color(0xFFFFA62B), // 橙
  Color(0xFF9B5DE5), // 紫
  Color(0xFF00BBF9), // 亮蓝
  Color(0xFFF15BB5), // 粉
  Color(0xFF8AC926), // 黄绿
  Color(0xFF1982C4), // 深蓝
  Color(0xFFFF7B00), // 深橙
  Color(0xFF6A4C93), // 深紫
  Color(0xFF20C997), // 墨绿
  Color(0xFFE76F51), // 砖红
  Color(0xFF457B9D), // 灰蓝
  Color(0xFFB5179E), // 洋红
  Color(0xFFF4A261), // 沙黄
  Color(0xFF38B000), // 草绿
  Color(0xFF3A0CA3), // 靛蓝
  Color(0xFFADB5BD), // 灰
  Color(0xFFD62828), // 深红
];

/// 按下标取色（自动循环）
Color chartColorAt(int index) =>
    kChartPalette[index % kChartPalette.length];
