class Bank {
  final int id;
  final String name;
  final String? description;
  final int? questionCount;
  final String? coverImage;

  Bank({
    required this.id,
    required this.name,
    this.description,
    this.questionCount,
    this.coverImage,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      questionCount: json['questionCount'] as int?,
      coverImage: json['coverImage'] as String?,
    );
  }
}
