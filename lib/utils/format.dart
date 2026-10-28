import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 金额格式化：¥1,234.50
String money(double v) =>
    NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2)
        .format(v);

/// 时间戳 -> yyyy-MM-dd
String ymd(int millis) =>
    DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(millis));

/// 账户类型元信息
const Map<String, Map<String, dynamic>> accountTypeMeta = {
  'cash': {'label': '现金', 'icon': Icons.money},
  'bank': {'label': '银行卡', 'icon': Icons.credit_card},
  'alipay': {'label': '支付宝', 'icon': Icons.account_balance_wallet},
  'wechat': {'label': '微信', 'icon': Icons.chat_bubble},
  'other': {'label': '其他', 'icon': Icons.more_horiz},
};

String accountTypeLabel(String type) =>
    accountTypeMeta[type]?['label'] as String? ?? '其他';
