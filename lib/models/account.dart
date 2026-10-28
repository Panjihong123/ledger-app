class Account {
  int? id;
  String name;
  String type; // cash / bank / alipay / wechat / other
  double initialBalance;
  double? currentBalance; // 由交易流水计算得出，不持久化

  Account({
    this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0,
    this.currentBalance,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'initialBalance': initialBalance,
      };

  factory Account.fromMap(Map<String, Object?> m) => Account(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        initialBalance: (m['initialBalance'] as num).toDouble(),
      );
}
