class Category {
  int? id;
  String name;
  String type; // expense / income
  int color; // 0xFF......
  String icon; // emoji
  int? parentId; // 一级分类为 null，二级分类指向一级分类 id

  Category({
    this.id,
    required this.name,
    required this.type,
    this.color = 0xFF9E9E9E,
    this.icon = '📦',
    this.parentId,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'icon': icon,
        'parentId': parentId,
      };

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        color: m['color'] as int,
        icon: m['icon'] as String,
        parentId: m['parentId'] as int?,
      );
}
