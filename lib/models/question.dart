import 'dart:convert';

/// 题目模型（参考 Android 版 Question）
/// type: 1-单选 2-多选 3-判断 4-填空 5-问答 6-材料
class Question {
  final int id;
  final String content;
  final int type;
  final String? options;
  final String? answer;
  final String? analysis;
  final Map<String, String>? optionsMap;
  final String? categoryName; // 分类名称，展示为标签
  final List<String>? tags;   // 后台标签列表

  Question({
    required this.id,
    required this.content,
    required this.type,
    this.options,
    this.answer,
    this.analysis,
    this.optionsMap,
    this.categoryName,
    this.tags,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      type: json['type'] as int? ?? 1,
      options: json['options'] as String?,
      answer: json['answer'] as String?,
      analysis: json['analysis'] as String?,
      optionsMap: (json['optionsMap'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, _cleanText(v.toString()))),
      categoryName: json['categoryName'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  /// 清洗文本中 Markdown 风格的转义反引号（\\` → `）
  static String _cleanText(String text) {
    return text.replaceAll(r'\`', '`');
  }

  /// 获取题型名称
  String get typeName {
    switch (type) {
      case 1:
        return '单选题';
      case 2:
        return '多选题';
      case 3:
        return '判断题';
      case 4:
        return '填空题';
      case 5:
        return '问答题';
      case 6:
        return '材料题';
      default:
        return '未知题型';
    }
  }

  /// 解析选项列表
  List<MapEntry<String, String>> get parsedOptions {
    // 优先使用 optionsMap
    if (optionsMap != null && optionsMap!.isNotEmpty) {
      return optionsMap!.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
    }

    // 尝试解析 options JSON
    if (options != null && options!.isNotEmpty) {
      try {
        final decoded = options!;
        // 尝试 JSON 格式
        if (decoded.startsWith('{')) {
          final map = jsonDecode(decoded) as Map<String, dynamic>;
          return map.entries
              .map((e) => MapEntry(e.key, _cleanText(e.value.toString())))
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
        }
        // 尝试 A.xxx|B.xxx 格式
        if (decoded.contains('|')) {
          return decoded.split('|').map((part) {
            final trimmed = part.trim();
            if (trimmed.contains('.')) {
              final dotIndex = trimmed.indexOf('.');
              return MapEntry(
                trimmed.substring(0, dotIndex).trim(),
                _cleanText(trimmed.substring(dotIndex + 1).trim()),
              );
            }
            return MapEntry('', _cleanText(trimmed));
          }).toList();
        }
        // 换行符格式
        if (decoded.contains('\n')) {
          return decoded.split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) {
            final trimmed = line.trim();
            if (trimmed.contains('.')) {
              final dotIndex = trimmed.indexOf('.');
              return MapEntry(
                trimmed.substring(0, dotIndex).trim(),
                _cleanText(trimmed.substring(dotIndex + 1).trim()),
              );
            }
            return MapEntry('', _cleanText(trimmed));
          }).toList();
        }
      } catch (_) {}
    }

    return [];
  }
}
