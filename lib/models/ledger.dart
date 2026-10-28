class Ledger {
  int? id;
  String name;
  bool isDefault;

  Ledger({this.id, required this.name, this.isDefault = false});

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'isDefault': isDefault ? 1 : 0,
      };

  factory Ledger.fromMap(Map<String, Object?> m) => Ledger(
        id: m['id'] as int?,
        name: m['name'] as String,
        isDefault: (m['isDefault'] as int) == 1,
      );
}
