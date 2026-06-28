/// 分类模型（参考 Android 版 Category）
class Category {
  final int id;
  final String name;
  final int? parentId;
  final int? sort;
  final List<Category>? children;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.sort,
    this.children,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      parentId: json['parentId'] as int?,
      sort: json['sort'] as int?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
