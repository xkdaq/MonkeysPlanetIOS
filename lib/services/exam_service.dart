import '../models/api_response.dart';
import '../models/bank.dart';
import '../models/category.dart';
import '../models/practice_record.dart';
import '../models/question.dart';
import 'auth_storage.dart';
import 'http_client.dart';

/// 题库/考试 API 服务（参考 Android 版 ExamApiService.kt + ExamRepository.kt）
class ExamService {
  late final HttpClient _client;

  ExamService(AuthStorage authStorage) {
    _client = HttpClient(authStorage);
  }

  /// 获取题库列表
  Future<ApiResponse<List<Bank>>> getBanks() async {
    final response = await _client.get('mp/exam/banks');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List).map((e) => Bank.fromJson(e)).toList(),
    );
  }

  /// 获取分类树
  Future<ApiResponse<List<Category>>> getCategoryTree(int bankId) async {
    final response = await _client.get(
      'mp/exam/category/tree',
      queryParameters: {'bankId': bankId},
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List).map((e) => Category.fromJson(e)).toList(),
    );
  }

  /// 获取题目详情
  Future<ApiResponse<Question>> getQuestion(int questionId) async {
    final response = await _client.get('mp/exam/question/$questionId');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Question.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 开始练习
  Future<ApiResponse<StartPracticeResult>> startPractice({
    required int bankId,
    int? categoryId,
    int practiceType = 1,
    int limit = 999,
  }) async {
    final params = <String, dynamic>{
      'bankId': bankId,
      'practiceType': practiceType,
      'limit': limit,
    };
    if (categoryId != null) {
      params['categoryId'] = categoryId;
    }
    final response = await _client.get(
      'mp/exam/practice/start',
      queryParameters: params,
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => StartPracticeResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 提交答案
  Future<ApiResponse<dynamic>> submitAnswer(int questionId, String answer) async {
    final response = await _client.post(
      'mp/exam/practice/submit',
      data: {'questionId': questionId, 'answer': answer},
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  /// 保存练习记录
  Future<ApiResponse<dynamic>> saveRecord({
    required int bankId,
    int? categoryId,
    required int practiceType,
    required int correctCount,
    required int wrongCount,
    required int totalCount,
    required int duration,
  }) async {
    final response = await _client.post(
      'mp/exam/practice/record',
      data: {
        'bankId': bankId,
        'categoryId': categoryId,
        'practiceType': practiceType,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'totalCount': totalCount,
        'duration': duration,
      },
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  /// 获取学习记录
  Future<ApiResponse<PracticeRecordPage>> getRecords({
    required int pageNum,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      'mp/exam/practice/records',
      queryParameters: {'pageNum': pageNum, 'pageSize': pageSize},
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => PracticeRecordPage.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 切换收藏
  Future<ApiResponse<bool>> toggleFavorite(int questionId) async {
    final response = await _client.post(
      'mp/exam/favorite',
      data: {'questionId': questionId},
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as bool,
    );
  }

  /// 检查收藏状态
  Future<ApiResponse<bool>> checkFavorite(int questionId) async {
    final response = await _client.get(
      'mp/exam/favorite/check',
      queryParameters: {'questionId': questionId},
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as bool,
    );
  }

  /// 获取收藏列表（bankId 可选，不传则返回全库）
  Future<ApiResponse<List<Question>>> getFavorites({int? bankId}) async {
    final params = bankId != null ? {'bankId': bankId} : null;
    final response = await _client.get('mp/exam/favorites', queryParameters: params);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List).map((e) {
        // API 返回 { question: {...}, ... }，取嵌套 question；若无则直接用外层
        final map = e as Map<String, dynamic>;
        final inner = map['question'] as Map<String, dynamic>?;
        return Question.fromJson(inner ?? map);
      }).toList(),
    );
  }

  /// 获取错题列表（bankId 可选，不传则返回全库）
  Future<ApiResponse<List<Question>>> getWrongs({int? bankId}) async {
    final params = bankId != null ? {'bankId': bankId} : null;
    final response = await _client.get('mp/exam/wrongs', queryParameters: params);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List).map((e) {
        // API 返回 { question: {...}, ... }，取嵌套 question；若无则直接用外层
        final map = e as Map<String, dynamic>;
        final inner = map['question'] as Map<String, dynamic>?;
        return Question.fromJson(inner ?? map);
      }).toList(),
    );
  }

  /// 移除错题
  Future<ApiResponse<dynamic>> removeWrong({required int questionId}) async {
    final response = await _client.post(
      'mp/exam/wrongs/remove',
      data: {'questionId': questionId},
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, (d) => d);
  }

  /// 题目纠错反馈
  Future<ApiResponse<dynamic>> reportQuestion({
    required int questionId,
    required String type,
    required String content,
  }) async {
    final response = await _client.post(
      'mp/exam/question/report',
      data: {
        'questionId': questionId,
        'type': type,
        'content': content,
      },
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }
}
