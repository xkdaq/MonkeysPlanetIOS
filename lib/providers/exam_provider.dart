import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/bank.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../models/practice_record.dart';
import '../services/auth_storage.dart';
import '../services/exam_service.dart';

/// 考试/刷题状态管理（参考 Android 版 ExamViewModel + ExamRepository）
class ExamProvider with ChangeNotifier {
  final AuthStorage _authStorage;
  late final ExamService _examService;

  // 题库列表
  List<Bank> _banks = [];
  bool _banksLoading = false;
  String? _banksError;

  // 分类树
  List<Category> _categories = [];
  bool _categoriesLoading = false;
  String? _categoriesError;
  int? _categoriesBankId; // 当前已加载分类所属的题库 ID

  // 练习
  List<Question> _practiceQuestions = [];
  bool _practiceLoading = false;
  String? _practiceError;

  // 题目
  Question? _currentQuestion;
  bool _questionLoading = false;
  String? _questionError;

  // 收藏
  final Set<int> _favoriteIds = {};
  bool _favoriteLoading = false;

  // 错题/收藏列表
  List<Question> _wrongQuestions = [];
  List<Question> _favoriteQuestions = [];
  bool _wrongLoading = false;
  bool _favoriteQuestionsLoading = false;

  // 学习记录
  PracticeRecordPage? _records;
  bool _recordsLoading = false;
  String? _recordsError;

  ExamProvider(this._authStorage) {
    _examService = ExamService(_authStorage);
  }

  // Getters
  List<Bank> get banks => _banks;
  bool get banksLoading => _banksLoading;
  String? get banksError => _banksError;

  List<Category> get categories => _categories;
  bool get categoriesLoading => _categoriesLoading;
  String? get categoriesError => _categoriesError;
  int? get categoriesBankId => _categoriesBankId;

  List<Question> get practiceQuestions => _practiceQuestions;
  bool get practiceLoading => _practiceLoading;
  String? get practiceError => _practiceError;

  Question? get currentQuestion => _currentQuestion;
  bool get questionLoading => _questionLoading;
  String? get questionError => _questionError;

  Set<int> get favoriteIds => _favoriteIds;
  bool get favoriteLoading => _favoriteLoading;

  List<Question> get wrongQuestions => _wrongQuestions;
  List<Question> get favoriteQuestions => _favoriteQuestions;
  bool get wrongLoading => _wrongLoading;
  bool get favoriteQuestionsLoading => _favoriteQuestionsLoading;

  PracticeRecordPage? get records => _records;
  bool get recordsLoading => _recordsLoading;
  String? get recordsError => _recordsError;

  /// 加载题库列表
  Future<void> loadBanks() async {
    _banksLoading = true;
    _banksError = null;
    notifyListeners();

    try {
      final result = await _examService.getBanks();
      if (result.isSuccess) {
        _banks = result.listData ?? [];
      } else {
        _banksError = result.msg ?? '获取题库失败';
      }
    } catch (e) {
      _banksError = _extractError(e, '获取题库失败');
    }
    _banksLoading = false;
    notifyListeners();
  }

  /// 加载分类树（先清空旧数据，避免切换题库时显示旧内容）
  Future<void> loadCategories(int bankId) async {
    _categories = [];
    _categoriesBankId = null; // 清空，防止首帧渲染到旧题库数据
    _categoriesLoading = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final result = await _examService.getCategoryTree(bankId);
      if (result.isSuccess) {
        _categories = result.listData ?? [];
        _categoriesBankId = bankId; // 仅成功时记录归属题库
      } else {
        _categoriesError = result.msg ?? '获取分类失败';
      }
    } catch (e) {
      _categoriesError = _extractError(e, '获取分类失败');
    }
    _categoriesLoading = false;
    notifyListeners();
  }

  /// 从异常中提取可读的错误信息
  String _extractError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['msg'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '请求超时，请检查网络';
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络';
        default:
          return fallback;
      }
    }
    return '网络异常，请稍后重试';
  }

  /// 开始练习
  /// practiceType: 1-顺序 2-随机 3-专项
  Future<List<Question>?> startPractice({
    required int bankId,
    int? categoryId,
    int practiceType = 1,
  }) async {
    _practiceLoading = true;
    _practiceError = null;
    _practiceQuestions = [];
    notifyListeners();

    try {
      // 顺序(1)和随机(2)限制20题，专项(3)全部
      final limit = (practiceType == 1 || practiceType == 2) ? 20 : 999;
      final result = await _examService.startPractice(
        bankId: bankId,
        categoryId: categoryId,
        practiceType: practiceType,
        limit: limit,
      );
      if (result.isSuccess && result.data != null) {
        _practiceQuestions = result.data!.questions;
        _practiceLoading = false;
        notifyListeners();
        return _practiceQuestions;
      } else {
        _practiceError = result.msg ?? '开始练习失败';
        _practiceLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _practiceError = _extractError(e, '开始练习失败');
      _practiceLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 获取题目详情
  Future<Question?> loadQuestion(int questionId) async {
    _questionLoading = true;
    _questionError = null;
    notifyListeners();

    try {
      final result = await _examService.getQuestion(questionId);
      if (result.isSuccess && result.data != null) {
        _currentQuestion = result.data;
        _questionLoading = false;
        notifyListeners();
        return result.data;
      } else {
        _questionError = result.msg ?? '获取题目失败';
        _questionLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _questionError = '网络异常';
      _questionLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 提交答案
  Future<bool> submitAnswer(int questionId, String answer) async {
    try {
      final result = await _examService.submitAnswer(questionId, answer);
      return result.isSuccess;
    } catch (_) {
      return false;
    }
  }

  /// 保存练习记录
  Future<bool> savePracticeRecord({
    required int bankId,
    int? categoryId,
    required int correctCount,
    required int wrongCount,
    required int totalCount,
    required int duration,
  }) async {
    try {
      final result = await _examService.saveRecord(
        bankId: bankId,
        categoryId: categoryId,
        correctCount: correctCount,
        wrongCount: wrongCount,
        totalCount: totalCount,
        duration: duration,
      );
      return result.isSuccess;
    } catch (_) {
      return false;
    }
  }

  /// 切换收藏
  Future<bool> toggleFavorite(int questionId) async {
    _favoriteLoading = true;
    notifyListeners();

    try {
      final result = await _examService.toggleFavorite(questionId);
      if (result.isSuccess) {
        if (_favoriteIds.contains(questionId)) {
          _favoriteIds.remove(questionId);
        } else {
          _favoriteIds.add(questionId);
        }
        _favoriteLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    _favoriteLoading = false;
    notifyListeners();
    return false;
  }

  /// 检查收藏状态
  Future<bool> checkFavorite(int questionId) async {
    try {
      final result = await _examService.checkFavorite(questionId);
      if (result.isSuccess && result.data != null) {
        if (result.data!) {
          _favoriteIds.add(questionId);
        } else {
          _favoriteIds.remove(questionId);
        }
        return result.data!;
      }
    } catch (_) {}
    return false;
  }

  /// 加载错题列表（bankId 可选，传入则只返回该题库的错题）
  Future<void> loadWrongQuestions({int? bankId}) async {
    _wrongLoading = true;
    notifyListeners();

    try {
      final result = await _examService.getWrongs(bankId: bankId);
      if (result.isSuccess) {
        _wrongQuestions = result.listData ?? [];
      }
    } catch (_) {}
    _wrongLoading = false;
    notifyListeners();
  }

  /// 加载收藏列表（bankId 可选，传入则只返回该题库的收藏）
  Future<void> loadFavoriteQuestions({int? bankId}) async {
    _favoriteQuestionsLoading = true;
    notifyListeners();

    try {
      final result = await _examService.getFavorites(bankId: bankId);
      if (result.isSuccess) {
        _favoriteQuestions = result.listData ?? [];
      }
    } catch (_) {}
    _favoriteQuestionsLoading = false;
    notifyListeners();
  }

  /// 移除错题（从列表中即时删除，无需重新请求）
  Future<bool> removeWrong(int questionId) async {
    try {
      final result = await _examService.removeWrong(questionId: questionId);
      if (result.isSuccess) {
        _wrongQuestions.removeWhere((q) => q.id == questionId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// 加载学习记录
  Future<void> loadRecords({int page = 1}) async {
    _recordsLoading = true;
    _recordsError = null;
    notifyListeners();

    try {
      final result = await _examService.getRecords(pageNum: page);
      if (result.isSuccess && result.data != null) {
        _records = result.data;
      } else {
        _recordsError = result.msg ?? '获取记录失败';
      }
    } catch (e) {
      _recordsError = '网络异常';
    }
    _recordsLoading = false;
    notifyListeners();
  }

  /// 清除练习数据
  void clearPractice() {
    _practiceQuestions = [];
    _practiceError = null;
  }
}
