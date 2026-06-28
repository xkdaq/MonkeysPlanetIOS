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
      _banksError = '网络异常，请检查网络连接';
    }
    _banksLoading = false;
    notifyListeners();
  }

  /// 加载分类树
  Future<void> loadCategories(int bankId) async {
    _categoriesLoading = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final result = await _examService.getCategoryTree(bankId);
      if (result.isSuccess) {
        _categories = result.listData ?? [];
      } else {
        _categoriesError = result.msg ?? '获取分类失败';
      }
    } catch (e) {
      _categoriesError = '网络异常';
    }
    _categoriesLoading = false;
    notifyListeners();
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
      _practiceError = '网络异常';
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

  /// 加载错题列表
  Future<void> loadWrongQuestions() async {
    _wrongLoading = true;
    notifyListeners();

    try {
      final result = await _examService.getWrongs();
      if (result.isSuccess) {
        _wrongQuestions = result.listData ?? [];
      }
    } catch (_) {}
    _wrongLoading = false;
    notifyListeners();
  }

  /// 加载收藏列表
  Future<void> loadFavoriteQuestions() async {
    _favoriteQuestionsLoading = true;
    notifyListeners();

    try {
      final result = await _examService.getFavorites();
      if (result.isSuccess) {
        _favoriteQuestions = result.listData ?? [];
      }
    } catch (_) {}
    _favoriteQuestionsLoading = false;
    notifyListeners();
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
