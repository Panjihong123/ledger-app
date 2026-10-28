class Category {
  int? id;
  String name;
  String type; // expense / income
  int color; // 0xFF......
  String icon; // emoji

  Category({
    this.id,
    required this.name,
    required this.type,
    this.color = 0xFF9E9E9E,
    this.icon = '📦',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'icon': icon,
      };

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        color: m['color'] as int,
        icon: m['icon'] as String,
      );
}
