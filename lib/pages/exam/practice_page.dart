import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/question.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/loading_indicator.dart';

/// 刷题页 - 核心答题页面（参考 Android 版 PracticeActivity）
class PracticePage extends StatefulWidget {
  final int bankId;
  final int? categoryId;
  final int practiceType; // 1-顺序 2-随机 3-专项
  final String? mode; // 'wrong' 或 'favorite'，用于错题/收藏模式
  final int? startIndex;

  const PracticePage({
    super.key,
    required this.bankId,
    this.categoryId,
    required this.practiceType,
    this.mode,
    this.startIndex,
  });

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  List<Question> _questions = [];
  int _currentIndex = 0;
  bool _isAnswerMode = true; // true-答题模式 false-背题模式
  bool _showAnswer = false;
  String? _userAnswer;
  bool _isCorrect = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;
  bool _loadingFavorite = false;
  DateTime _startTime = DateTime.now();

  // 多选题
  final Set<String> _selectedMultipleOptions = {};
  bool _multipleSubmitted = false;

  // 错题/收藏模式
  bool get _isWrongMode => widget.mode == 'wrong';
  bool get _isFavoriteMode => widget.mode == 'favorite';

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final examProvider = context.read<ExamProvider>();

      if (_isWrongMode) {
        await examProvider.loadWrongQuestions();
        _questions = examProvider.wrongQuestions;
      } else if (_isFavoriteMode) {
        await examProvider.loadFavoriteQuestions();
        _questions = examProvider.favoriteQuestions;
      } else {
        final questions = await examProvider.startPractice(
          bankId: widget.bankId,
          categoryId: widget.categoryId,
          practiceType: widget.practiceType,
        );
        if (questions != null) {
          _questions = questions;
        }
      }

      if (_questions.isEmpty) {
        setState(() {
          _errorMessage = '暂无题目';
          _isLoading = false;
        });
        return;
      }

      // 设置初始索引
      if (widget.startIndex != null && widget.startIndex! < _questions.length) {
        _currentIndex = widget.startIndex!;
      }

      // 检查当前题目收藏状态
      await _checkFavoriteStatus();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (_currentIndex < _questions.length && mounted) {
      final examProvider = context.read<ExamProvider>();
      final isFav = await examProvider.checkFavorite(_questions[_currentIndex].id);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    }
  }

  Question get _currentQuestion => _questions[_currentIndex];
  bool get _isLast => _currentIndex >= _questions.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1}/${_questions.length}'),
        actions: [
          // 答题/背题模式切换
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isAnswerMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isAnswerMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '答题',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isAnswerMode ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAnswerMode = false;
                      _showAnswer = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isAnswerMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '背题',
                      style: TextStyle(
                        fontSize: 13,
                        color: !_isAnswerMode ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _questions.isNotEmpty
              ? LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: AppColors.bgDivider,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                )
              : const SizedBox(),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: '加载题目中...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadQuestions,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(child: Text('暂无题目', style: TextStyle(color: AppColors.textHint)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 题型标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _currentQuestion.typeName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 题目内容（HTML渲染）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.bgDivider, width: 0.5),
            ),
            child: SelectableText(
              _stripHtmlTags(_currentQuestion.content),
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 选项区域
          ..._buildOptions(),

          // 提交答案按钮（多选）
          if (_currentQuestion.type == 2 && _isAnswerMode && !_multipleSubmitted && _selectedMultipleOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _submitMultipleAnswer,
                  child: const Text('提交答案'),
                ),
              ),
            ),

          // 收藏按钮
          Center(
            child: IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? AppColors.warningOrange : AppColors.textHint,
                size: 28,
              ),
            ),
          ),

          // 解析区域
          if (_showAnswer && _currentQuestion.analysis != null && _currentQuestion.analysis!.isNotEmpty)
            _buildAnalysisSection(),
        ],
      ),
    );
  }

  List<Widget> _buildOptions() {
    final question = _currentQuestion;
    final options = question.parsedOptions;

    if (options.isEmpty) return [];

    // 判断题特殊处理
    if (question.type == 3) {
      return _buildJudgeOptions();
    }

    return options.map((option) {
      final isSelected = _userAnswer == option.key;
      final isCorrectAnswer = question.answer == option.key;
      final isWrongSelection = _showAnswer && isSelected && !isCorrectAnswer;
      final isMissed = _showAnswer && isCorrectAnswer && _userAnswer != null && !isSelected && !isCorrectAnswer;

      Color bgColor;
      Color textColor;
      Color borderColor;

      if (_showAnswer) {
        if (isCorrectAnswer) {
          bgColor = AppColors.correctGreen.withValues(alpha: 0.1);
          textColor = AppColors.correctGreen;
          borderColor = AppColors.correctGreen;
        } else if (isWrongSelection) {
          bgColor = AppColors.wrongRed.withValues(alpha: 0.1);
          textColor = AppColors.wrongRed;
          borderColor = AppColors.wrongRed;
        } else if (isMissed) {
          bgColor = AppColors.warningOrange.withValues(alpha: 0.1);
          textColor = AppColors.warningOrange;
          borderColor = AppColors.warningOrange;
        } else {
          bgColor = AppColors.bgWhite;
          textColor = AppColors.textPrimary;
          borderColor = AppColors.bgDivider;
        }
      } else if (isSelected) {
        bgColor = AppColors.primaryLight;
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
      } else if (question.type == 2 && _selectedMultipleOptions.contains(option.key)) {
        bgColor = AppColors.primaryLight;
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
      } else {
        bgColor = AppColors.bgGray;
        textColor = AppColors.textPrimary;
        borderColor = AppColors.bgGray;
      }

      return GestureDetector(
        onTap: _showAnswer ? null : () => _onOptionTap(option.key),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${option.key}. ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Expanded(
                child: Text(
                  option.value,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              ),
              if (_showAnswer && isCorrectAnswer)
                const Icon(Icons.check_circle, color: AppColors.correctGreen, size: 20),
              if (_showAnswer && isWrongSelection)
                const Icon(Icons.cancel, color: AppColors.wrongRed, size: 20),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildJudgeOptions() {
    final judgeOptions = ['正确', '错误'];
    return judgeOptions.map((label) {
      final value = label == '正确' ? 'A' : 'B';
      final isSelected = _userAnswer == value;
      final isCorrectAnswer = _currentQuestion.answer == value;
      final isWrongSelection = _showAnswer && isSelected && !isCorrectAnswer;

      Color bgColor;
      Color textColor;
      Color borderColor;

      if (_showAnswer) {
        if (isCorrectAnswer) {
          bgColor = AppColors.correctGreen.withValues(alpha: 0.1);
          textColor = AppColors.correctGreen;
          borderColor = AppColors.correctGreen;
        } else if (isWrongSelection) {
          bgColor = AppColors.wrongRed.withValues(alpha: 0.1);
          textColor = AppColors.wrongRed;
          borderColor = AppColors.wrongRed;
        } else {
          bgColor = AppColors.bgWhite;
          textColor = AppColors.textPrimary;
          borderColor = AppColors.bgDivider;
        }
      } else if (isSelected) {
        bgColor = AppColors.primaryLight;
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
      } else {
        bgColor = AppColors.bgGray;
        textColor = AppColors.textPrimary;
        borderColor = AppColors.bgGray;
      }

      return GestureDetector(
        onTap: _showAnswer ? null : () => _onOptionTap(value),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(fontSize: 15, color: textColor),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _onOptionTap(String optionKey) {
    if (mounted && !_showAnswer) {
      setState(() {
        // 单选题和判断题：点击直接提交
        if (_currentQuestion.type == 1 || _currentQuestion.type == 3) {
          _userAnswer = optionKey;
          _submitAnswer();
        }
        // 多选题：切换选择
        else if (_currentQuestion.type == 2) {
          if (_selectedMultipleOptions.contains(optionKey)) {
            _selectedMultipleOptions.remove(optionKey);
          } else {
            _selectedMultipleOptions.add(optionKey);
          }
        }
      });
    }
  }

  void _submitAnswer() {
    if (_userAnswer == null) return;

    final correctAnswer = _currentQuestion.answer ?? '';
    
    // 比较答案
    if (_currentQuestion.type == 2) {
      // 多选题：排序后比较
      final userAnswerSorted = _selectedMultipleOptions.toList()..sort();
      final correctSorted = correctAnswer.split('').map((s) => s.trim()).toList()..sort();
      _isCorrect = _listEquals(userAnswerSorted, correctSorted);
      _userAnswer = _selectedMultipleOptions.join(',');
    } else {
      _isCorrect = _userAnswer!.trim().toUpperCase() == correctAnswer.trim().toUpperCase();
    }

    if (_isCorrect) {
      _correctCount++;
    } else {
      _wrongCount++;
    }

    setState(() {
      _showAnswer = true;
    });

    // 提交答案到服务器
    context.read<ExamProvider>().submitAnswer(_currentQuestion.id, _userAnswer ?? '');
  }

  void _submitMultipleAnswer() {
    setState(() {
      _multipleSubmitted = true;
    });
    _submitAnswer();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildAnalysisSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? AppColors.correctGreen : AppColors.wrongRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isCorrect ? '回答正确' : '回答错误',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isCorrect ? AppColors.correctGreen : AppColors.wrongRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('正确答案: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              Text(
                _currentQuestion.answer ?? '',
                style: const TextStyle(
                  color: AppColors.correctGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_userAnswer != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('你的答案: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                Text(
                  _userAnswer!,
                  style: TextStyle(
                    color: _isCorrect ? AppColors.correctGreen : AppColors.wrongRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Text('解析', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          SelectableText(
            _stripHtmlTags(_currentQuestion.analysis ?? ''),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_questions.isEmpty) return const SizedBox();

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.bgDivider, width: 0.5)),
        color: AppColors.bgWhite,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 上一题
          Expanded(
            child: TextButton(
              onPressed: _currentIndex > 0 ? _goToPrevious : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                disabledForegroundColor: AppColors.textHint,
              ),
              child: const Text('上一题'),
            ),
          ),
          const SizedBox(width: 12),
          // 答题卡
          TextButton.icon(
            onPressed: _showQuestionNav,
            icon: const Icon(Icons.grid_view, size: 18),
            label: const Text('答题卡'),
          ),
          const SizedBox(width: 12),
          // 下一题/完成
          Expanded(
            child: ElevatedButton(
              onPressed: _isLast ? _finishPractice : _goToNext,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              child: Text(_isLast ? '完成' : '下一题'),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNext() {
    if (_currentIndex < _questions.length - 1) {
      _resetForNextQuestion();
      setState(() {
        _currentIndex++;
      });
      _checkFavoriteStatus();
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _resetForNextQuestion();
      setState(() {
        _currentIndex--;
      });
      _checkFavoriteStatus();
    }
  }

  void _resetForNextQuestion() {
    setState(() {
      _showAnswer = false;
      _userAnswer = null;
      _isCorrect = false;
      _selectedMultipleOptions.clear();
      _multipleSubmitted = false;
    });
  }

  void _showQuestionNav() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '答题卡',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _navBadge('已答', '$_correctCount', AppColors.correctGreen),
                  const SizedBox(width: 16),
                  _navBadge('总题', '${_questions.length}', AppColors.primary),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_questions.length, (index) {
                  final isCurrent = index == _currentIndex;
                  return GestureDetector(
                    onTap: () {
                      _resetForNextQuestion();
                      setState(() => _currentIndex = index);
                      Navigator.pop(context);
                      _checkFavoriteStatus();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.bgGray,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? null
                            : Border.all(color: AppColors.bgDivider),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isCurrent ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navBadge(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$label: $value',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Future<void> _toggleFavorite() async {
    if (_loadingFavorite) return;
    _loadingFavorite = true;

    final examProvider = context.read<ExamProvider>();
    await examProvider.toggleFavorite(_currentQuestion.id);

    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _loadingFavorite = false;
      });
    }
  }

  Future<void> _finishPractice() async {
    final duration = DateTime.now().difference(_startTime).inSeconds;

    // 保存练习记录
    if (!_isWrongMode && !_isFavoriteMode) {
      await context.read<ExamProvider>().savePracticeRecord(
        bankId: widget.bankId,
        categoryId: widget.categoryId,
        correctCount: _correctCount,
        wrongCount: _wrongCount,
        totalCount: _correctCount + _wrongCount,
        duration: duration,
      );
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('练习完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('恭喜你完成本次练习！'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem('总题', '${_correctCount + _wrongCount}'),
                  _statItem('正确', '$_correctCount', AppColors.correctGreen),
                  _statItem('错误', '$_wrongCount', AppColors.wrongRed),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  Widget _statItem(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  /// 简单去除 HTML 标签
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
