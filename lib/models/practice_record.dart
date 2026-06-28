import 'question.dart';

/// 开始练习结果（参考 Android 版 StartPracticeResult）
class StartPracticeResult {
  final List<Question> questions;
  final int total;
  final int? practiceType;
  final int? bankId;

  StartPracticeResult({
    required this.questions,
    required this.total,
    this.practiceType,
    this.bankId,
  });

  factory StartPracticeResult.fromJson(Map<String, dynamic> json) {
    return StartPracticeResult(
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      practiceType: json['practiceType'] as int?,
      bankId: json['bankId'] as int?,
    );
  }
}

/// 练习记录（参考 Android 版 PracticeRecord）
class PracticeRecord {
  final int id;
  final int practiceType;
  final String practiceTypeName;
  final int totalCount;
  final int correctCount;
  final int accuracy;
  final int duration;
  final String durationText;
  final String createTime;
  final String bankName;

  PracticeRecord({
    required this.id,
    required this.practiceType,
    required this.practiceTypeName,
    required this.totalCount,
    required this.correctCount,
    required this.accuracy,
    required this.duration,
    required this.durationText,
    required this.createTime,
    required this.bankName,
  });

  factory PracticeRecord.fromJson(Map<String, dynamic> json) {
    return PracticeRecord(
      id: json['id'] as int? ?? 0,
      practiceType: json['practiceType'] as int? ?? 0,
      practiceTypeName: json['practiceTypeName'] as String? ?? '',
      totalCount: json['totalCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      accuracy: json['accuracy'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      durationText: json['durationText'] as String? ?? '',
      createTime: json['createTime'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
    );
  }
}

/// 练习记录分页（参考 Android 版 PracticeRecordPage）
class PracticeRecordPage {
  final List<PracticeRecord> list;
  final int total;
  final int totalQuestions;
  final int totalCorrect;
  final String totalDurationText;

  PracticeRecordPage({
    required this.list,
    required this.total,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.totalDurationText,
  });

  factory PracticeRecordPage.fromJson(Map<String, dynamic> json) {
    return PracticeRecordPage(
      list: (json['list'] as List<dynamic>?)
              ?.map((e) => PracticeRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      totalDurationText: json['totalDurationText'] as String? ?? '',
    );
  }
}

/// 答题记录（参考 Android 版 AnswerRecord）
class AnswerRecord {
  final int questionId;
  final String userAnswer;
  final bool isCorrect;

  AnswerRecord({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    };
  }
}
