/// 题库模型（参考 Android 版 Bank）
class Bank {
  final int id;
  final String name;
  final String? description;
  final int? questionCount;

  Bank({
    required this.id,
    required this.name,
    this.description,
    this.questionCount,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      questionCount: json['questionCount'] as int?,
    );
  }
}
