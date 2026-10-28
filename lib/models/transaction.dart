class Txn {
  int? id;
  int ledgerId;
  int accountId;
  int categoryId;
  String type; // expense / income
  double amount;
  int date; // 毫秒时间戳
  String? note;

  Txn({
    this.id,
    required this.ledgerId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'ledgerId': ledgerId,
        'accountId': accountId,
        'categoryId': categoryId,
        'type': type,
        'amount': amount,
        'date': date,
        'note': note,
      };

  factory Txn.fromMap(Map<String, Object?> m) => Txn(
        id: m['id'] as int?,
        ledgerId: m['ledgerId'] as int,
        accountId: m['accountId'] as int,
        categoryId: m['categoryId'] as int,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: m['date'] as int,
        note: m['note'] as String?,
      );
}
