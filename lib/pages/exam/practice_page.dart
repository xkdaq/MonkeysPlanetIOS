import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../models/question.dart';
import '../../providers/exam_provider.dart';
import '../../services/auth_storage.dart';
import '../../services/visit_report_service.dart';
import '../profile/login_page.dart';
import '../../widgets/html_content.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_dialog.dart';

class PracticePage extends StatefulWidget {
  final int bankId;
  final int? categoryId;
  final int practiceType;
  final String? mode;
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
  bool _isAnswerMode = true;
  bool _showAnswer = false;
  String? _userAnswer;
  bool _isCorrect = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;
  bool _loadingFavorite = false;
  bool _removingWrong = false;
  DateTime _startTime = DateTime.now();

  // 多选题
  final Set<String> _multiSelected = {};

  // 每题答题记录（进度保存/恢复）
  final Map<int, _QuestionAnswer> _answers = {};

  bool get _isWrongMode => widget.mode == 'wrong';
  bool get _isFavoriteMode => widget.mode == 'favorite';
  bool get _isLast => _currentIndex >= _questions.length - 1;
  Question get _current => _questions[_currentIndex];

  String get _progressKey =>
      'practice_progress_${widget.bankId}_${widget.categoryId ?? 0}_${widget.practiceType}';

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final provider = context.read<ExamProvider>();
      if (_isWrongMode) {
        await provider.loadWrongQuestions(bankId: widget.bankId);
        if (!mounted) return;
        _questions = List.from(provider.wrongQuestions);
      } else if (_isFavoriteMode) {
        await provider.loadFavoriteQuestions(bankId: widget.bankId);
        if (!mounted) return;
        _questions = List.from(provider.favoriteQuestions);
      } else {
        final qs = await provider.startPractice(
          bankId: widget.bankId,
          categoryId: widget.categoryId,
          practiceType: widget.practiceType,
        );
        if (qs != null) {
          _questions = qs;
          // 开始练习成功，上报
          VisitReportService(AuthStorage()).reportPracticeStart(
            pagePath: 'practice/${widget.bankId}',
            bankId: widget.bankId,
          );
        } else {
          final err = provider.practiceError ?? '';
          if (err.contains('请先登录') || err.contains('未登录')) {
            if (mounted) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
            }
            return;
          }
          setState(() { _errorMessage = err.isNotEmpty ? err : '暂无题目'; _isLoading = false; });
          return;
        }
      }
      if (_questions.isEmpty) {
        setState(() { _errorMessage = '暂无题目'; _isLoading = false; });
        return;
      }
      if (widget.startIndex != null && widget.startIndex! < _questions.length) {
        _currentIndex = widget.startIndex!;
      }
      setState(() => _isLoading = false);
      // 检查并弹框恢复进度（wrong/favorite 模式跳过）
      if (!_isWrongMode && !_isFavoriteMode) {
        await _checkAndRestoreProgress();
      }
      await _checkFavorite();
    } catch (e) {
      setState(() { _errorMessage = '加载失败'; _isLoading = false; });
    }
  }

  // ──────────── 进度保存/恢复 ────────────

  Future<void> _saveProgress() async {
    if (_isWrongMode || _isFavoriteMode || _questions.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    // 已全部完成则清除
    if (_currentIndex >= _questions.length - 1 && _answers.length >= _questions.length) {
      await prefs.remove(_progressKey);
      return;
    }
    final answersJson = _answers.map((id, a) => MapEntry(
      id.toString(),
      {'userAnswer': a.userAnswer, 'isCorrect': a.isCorrect},
    ));
    final data = jsonEncode({
      'currentIndex': _currentIndex,
      'questionIds': _questions.map((q) => q.id).toList(),
      'answers': answersJson,
      'correctCount': _correctCount,
      'wrongCount': _wrongCount,
      'durationOffset': DateTime.now().difference(_startTime).inSeconds,
    });
    await prefs.setString(_progressKey, data);
  }

  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
  }

  Future<void> _checkAndRestoreProgress() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_progressKey);
    if (saved == null) return;

    try {
      final progress = jsonDecode(saved) as Map<String, dynamic>;
      final savedIds = (progress['questionIds'] as List).map((e) => e as int).toList();
      final currentIds = _questions.map((q) => q.id).toList();

      // 题目列表不一致则清除旧进度
      if (savedIds.length != currentIds.length ||
          !List.generate(savedIds.length, (i) => savedIds[i] == currentIds[i]).every((e) => e)) {
        await prefs.remove(_progressKey);
        return;
      }

      final savedIndex = progress['currentIndex'] as int;
      if (savedIndex <= 0 && (progress['answers'] as Map).isEmpty) return;

      final savedCorrect = progress['correctCount'] as int;
      final savedWrong = progress['wrongCount'] as int;
      final durationSecs = progress['durationOffset'] as int;
      final answeredCount = (progress['answers'] as Map).length;
      final mins = durationSecs ~/ 60;
      final secs = durationSecs % 60;

      if (!mounted) return;
      final resume = await AppDialog.show<bool>(
        context: context,
        title: '继续上次练习',
        message: '已做 $answeredCount/${_questions.length} 题，'
            '答对 $savedCorrect 题，用时 $mins 分 $secs 秒\n是否继续上次的进度？',
        actions: [
          AppDialogAction(
            text: '重新开始',
            style: AppDialogActionStyle.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            text: '继续练习',
            isDefault: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );

      if (!mounted) return;
      if (resume == true) {
        final rawAnswers = progress['answers'] as Map<String, dynamic>;
        setState(() {
          for (final entry in rawAnswers.entries) {
            final id = int.parse(entry.key);
            final map = entry.value as Map<String, dynamic>;
            _answers[id] = _QuestionAnswer(
              map['userAnswer'] as String,
              map['isCorrect'] as bool,
            );
          }
          _correctCount = savedCorrect;
          _wrongCount = savedWrong;
          _startTime = DateTime.now().subtract(Duration(seconds: durationSecs));
          _navigateToQuestionNoFavorite(savedIndex);
        });
      } else {
        await prefs.remove(_progressKey);
      }
    } catch (_) {
      await prefs.remove(_progressKey);
    }
  }

  Future<void> _checkFavorite() async {
    if (_questions.isEmpty || !mounted) return;
    final isFav = await context.read<ExamProvider>().checkFavorite(_current.id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: '加载题目中...')
            : _errorMessage != null
                ? _buildError()
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(13),
                          child: _buildBody(),
                        ),
                      ),
                      _buildFooter(),
                    ],
                  ),
      ),
    );
  }

  // ──────────── Header ────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, size: 17, color: AppColors.textPrimary),
              ),
              Expanded(
                child: Center(
                  child: _questions.isEmpty
                      ? const SizedBox()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${_currentIndex + 1}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            Text(
                              '/${_questions.length}',
                              style: const TextStyle(fontSize: 14, color: AppColors.textHint),
                            ),
                          ],
                        ),
                ),
              ),
              _buildModeSwitch(),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _questions.isEmpty ? 0 : (_currentIndex + 1) / _questions.length,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeItem('答题', true),
          _modeItem('背题', false),
        ],
      ),
    );
  }

  Widget _modeItem(String label, bool isAnswer) {
    final active = _isAnswerMode == isAnswer;
    return GestureDetector(
      onTap: () => setState(() {
        _isAnswerMode = isAnswer;
        if (!isAnswer) {
          // 切换到背题：立即显示答案
          _showAnswer = true;
        } else {
          // 切换回答题：只有用户未实际作答时才隐藏解析
          if (_userAnswer == null && _multiSelected.isEmpty) {
            _showAnswer = false;
          }
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: active ? [const BoxShadow(color: Color(0x18000000), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ──────────── Body ────────────

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionCard(),
        const SizedBox(height: 13),
        ..._buildOptions(),
        if (_current.type == 2 && _isAnswerMode && !_showAnswer && _multiSelected.isNotEmpty)
          _buildMultiSubmitBtn(),
        if (_showAnswer) ...[
          const SizedBox(height: 13),
          _buildAnalysis(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final tag = _current.categoryName?.isNotEmpty == true
        ? _current.categoryName!
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tag != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(tag, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
            const SizedBox(height: 10),
          ],
          HtmlContent(
            html: _current.content,
            baseStyle: const TextStyle(fontSize: 15, height: 1.8, color: AppColors.textPrimary),
            selectable: true,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions() {
    final q = _current;
    if (q.type == 3) return _buildJudgeOptions();

    final opts = q.parsedOptions;
    if (opts.isEmpty) return [];

    return opts.map((opt) {
      final key = opt.key;
      final isMultiSelected = _multiSelected.contains(key);
      final isCorrectOpt = q.answer?.contains(key) == true;
      final isUserSelected = q.type == 2 ? isMultiSelected : (_userAnswer == key);
      final isWrong = _showAnswer && isUserSelected && !isCorrectOpt;
      final isMissed = _showAnswer && isCorrectOpt && !isUserSelected && _userAnswer != null;

      Color bg, border, labelBg, labelColor;
      Widget? statusIcon;

      if (_showAnswer) {
        if (isCorrectOpt) {
          bg = const Color(0xFFE8F5E9);
          border = AppColors.primary;
          labelBg = AppColors.primary;
          labelColor = Colors.white;
          statusIcon = const Icon(Icons.check_circle, color: AppColors.primary, size: 18);
        } else if (isWrong) {
          bg = const Color(0xFFFFEBEE);
          border = AppColors.wrongRed;
          labelBg = AppColors.wrongRed;
          labelColor = Colors.white;
          statusIcon = const Icon(Icons.cancel, color: AppColors.wrongRed, size: 18);
        } else if (isMissed) {
          bg = const Color(0xFFFFFBE6);
          border = const Color(0xFFFAAD14);
          labelBg = const Color(0xFFFAAD14);
          labelColor = Colors.white;
        } else {
          bg = Colors.white;
          border = Colors.transparent;
          labelBg = const Color(0xFFF0F0F0);
          labelColor = AppColors.textSecondary;
        }
      } else if (isUserSelected) {
        bg = Colors.white;
        border = const Color(0xFFD9D9D9);
        labelBg = AppColors.primary;
        labelColor = Colors.white;
      } else {
        bg = Colors.white;
        border = Colors.transparent;
        labelBg = const Color(0xFFF0F0F0);
        labelColor = AppColors.textSecondary;
      }

      return GestureDetector(
        onTap: _showAnswer ? null : () => _onOptionTap(key),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: border == Colors.transparent ? 0 : 1),
            boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 1))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: labelBg, shape: BoxShape.circle),
                child: Center(
                  child: Text(key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(opt.value, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimary)),
              ),
              if (statusIcon != null) ...[const SizedBox(width: 6), statusIcon],
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildJudgeOptions() {
    return [
      _judgeOption('正确', 'A'),
      _judgeOption('错误', 'B'),
    ];
  }

  Widget _judgeOption(String label, String value) {
    final q = _current;
    final isSelected = _userAnswer == value;
    final isCorrectOpt = q.answer?.toUpperCase() == value;
    final isWrong = _showAnswer && isSelected && !isCorrectOpt;

    Color bg, border, labelBg, labelColor;
    Widget? statusIcon;

    if (_showAnswer) {
      if (isCorrectOpt) {
        bg = const Color(0xFFE8F5E9); border = AppColors.primary;
        labelBg = AppColors.primary; labelColor = Colors.white;
        statusIcon = const Icon(Icons.check_circle, color: AppColors.primary, size: 18);
      } else if (isWrong) {
        bg = const Color(0xFFFFEBEE); border = AppColors.wrongRed;
        labelBg = AppColors.wrongRed; labelColor = Colors.white;
        statusIcon = const Icon(Icons.cancel, color: AppColors.wrongRed, size: 18);
      } else {
        bg = Colors.white; border = Colors.transparent;
        labelBg = const Color(0xFFF0F0F0); labelColor = AppColors.textSecondary;
      }
    } else if (isSelected) {
      bg = Colors.white; border = const Color(0xFFD9D9D9);
      labelBg = AppColors.primary; labelColor = Colors.white;
    } else {
      bg = Colors.white; border = Colors.transparent;
      labelBg = const Color(0xFFF0F0F0); labelColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: _showAnswer ? null : () => _onOptionTap(value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: border == Colors.transparent ? 0 : 1),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: labelBg, shape: BoxShape.circle),
              child: Center(
                child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
            ?statusIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSubmitBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: _submitAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          child: const Text('提交答案'),
        ),
      ),
    );
  }

  // ──────────── Analysis ────────────

  Widget _buildAnalysis() {
    final hasAnalysis = _current.analysis?.isNotEmpty == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 答案对比
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _compareItem('正确答案', _current.answer ?? '-', AppColors.primary),
                Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                _compareItem(
                  '你的答案',
                  _userAnswer ?? (_isAnswerMode ? '未作答' : '-'),
                  _userAnswer != null ? (_isCorrect ? AppColors.primary : AppColors.wrongRed) : AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // 文本解析
          if (hasAnalysis)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 标题行（含复制按钮）
                  Row(
                    children: [
                      const _SectionLabel(title: '文本解析'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _stripHtml(_current.analysis!)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('解析已复制'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('复制', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HtmlContent(
                      html: _current.analysis!,
                      baseStyle: const TextStyle(fontSize: 14, height: 1.7, color: AppColors.textPrimary),
                      selectable: true,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _compareItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }

  // ──────────── Footer ────────────

  Widget _buildFooter() {
    if (_questions.isEmpty) return const SizedBox();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.bgDivider, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          // 上一题
          Expanded(
            child: GestureDetector(
              onTap: _currentIndex > 0 ? _goToPrev : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 18),
                decoration: BoxDecoration(
                  color: _currentIndex > 0 ? const Color(0xFFF0F0F0) : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    '上一题',
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentIndex > 0 ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 中部：答题卡 + 收藏（+ 错题模式下的移除）
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                _footerAction('▦', '答题卡', _showNav, active: false),
                _footerAction(
                  _isFavorite ? '★' : '☆',
                  _isFavorite ? '已收藏' : '收藏',
                  _toggleFavorite,
                  active: _isFavorite,
                ),
                if (_isWrongMode)
                  _footerAction('✕', '移除', _removeCurrentWrong, active: false, activeColor: Colors.red),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 下一题 / 交卷
          Expanded(
            child: GestureDetector(
              onTap: _isLast ? _finish : _goToNext,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 18),
                decoration: BoxDecoration(
                  color: _isLast ? const Color(0xFFFF7A45) : AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    _isLast ? '交卷' : '下一题',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerAction(String symbol, String label, VoidCallback onTap, {required bool active, Color? activeColor}) {
    final accent = activeColor ?? AppColors.primary;
    final iconBgActive = activeColor != null ? activeColor.withValues(alpha: 0.12) : const Color(0xFFDFF5E8);
    final pillBgActive = activeColor != null ? activeColor.withValues(alpha: 0.07) : const Color(0xFFE8F7EF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active ? pillBgActive : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: active ? iconBgActive : const Color(0xFFEEF0F3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: active ? accent : (activeColor ?? const Color(0xFF8A9099)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? accent : (activeColor ?? AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────── Logic ────────────

  // ──────────── 题目导航（含历史答题恢复） ────────────

  void _navigateToQuestionNoFavorite(int index) {
    if (index < 0 || index >= _questions.length) return;
    _currentIndex = index;
    final existing = _answers[_questions[index].id];
    if (existing != null) {
      _userAnswer = existing.userAnswer;
      _isCorrect = existing.isCorrect;
      _showAnswer = true;
      _multiSelected.clear();
      if (_questions[index].type == 2) {
        for (final c in existing.userAnswer.split('')) {
          _multiSelected.add(c);
        }
      }
    } else {
      _showAnswer = !_isAnswerMode;
      _userAnswer = null;
      _isCorrect = false;
      _multiSelected.clear();
    }
  }

  void _navigateTo(int index) {
    setState(() => _navigateToQuestionNoFavorite(index));
    _checkFavorite();
  }

  void _onOptionTap(String key) {
    if (_showAnswer) return;
    if (_current.type == 2) {
      setState(() {
        if (_multiSelected.contains(key)) {
          _multiSelected.remove(key);
        } else {
          _multiSelected.add(key);
        }
      });
    } else {
      _userAnswer = key;
      _submitAnswer();
    }
  }

  void _submitAnswer() {
    // 多选题：从 _multiSelected 构建答案
    if (_current.type == 2) {
      if (_multiSelected.isEmpty) return;
      _userAnswer = (_multiSelected.toList()..sort()).join('');
    }

    if (_userAnswer == null || _userAnswer!.isEmpty) return;

    final correct = _current.answer ?? '';

    if (_current.type == 2) {
      // 多选：排序后对比
      final ua = _userAnswer!.split('').toList()..sort();
      final ca = correct.split('').where((s) => s.trim().isNotEmpty).toList()..sort();
      _isCorrect = _listEq(ua, ca);
    } else {
      _isCorrect = _userAnswer!.trim().toUpperCase() == correct.trim().toUpperCase();
    }

    if (_isCorrect) { _correctCount++; } else { _wrongCount++; }

    // 记录本题答案，用于进度保存和切题后恢复
    _answers[_current.id] = _QuestionAnswer(_userAnswer!, _isCorrect);

    setState(() => _showAnswer = true);

    context.read<ExamProvider>().submitAnswer(_current.id, _userAnswer ?? '');
    _saveProgress();
  }

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _goToNext() {
    if (_currentIndex < _questions.length - 1) {
      _navigateTo(_currentIndex + 1);
    }
  }

  void _goToPrev() {
    if (_currentIndex > 0) {
      _navigateTo(_currentIndex - 1);
    }
  }

  void _resetQuestion() {
    _showAnswer = !_isAnswerMode;
    _userAnswer = null;
    _isCorrect = false;
    _multiSelected.clear();
  }

  Future<void> _toggleFavorite() async {
    if (_loadingFavorite) return;
    setState(() => _loadingFavorite = true);
    final ok = await context.read<ExamProvider>().toggleFavorite(_current.id);
    if (mounted) setState(() { if (ok) _isFavorite = !_isFavorite; _loadingFavorite = false; });
  }

  Future<void> _removeCurrentWrong() async {
    if (_removingWrong) return;
    final questionId = _current.id;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: '移除错题',
      message: '确定将此题从错题本中移除吗？',
      actions: [
        AppDialogAction(
          text: '取消',
          style: AppDialogActionStyle.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          text: '移除',
          style: AppDialogActionStyle.destructive,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingWrong = true);
    final ok = await context.read<ExamProvider>().removeWrong(questionId);
    if (!mounted) return;
    setState(() => _removingWrong = false);

    if (ok) {
      _questions.removeWhere((q) => q.id == questionId);
      if (!mounted) return;
      if (_questions.isEmpty) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        if (_currentIndex >= _questions.length) _currentIndex = _questions.length - 1;
        _resetQuestion();
      });
      await _checkFavorite();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('移除失败，请稍后重试'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _showNav() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionNavSheet(
        total: _questions.length,
        current: _currentIndex,
        onSelect: (i) {
          Navigator.pop(ctx);
          _navigateTo(i);
        },
        onRedo: () {
          Navigator.pop(ctx);
          _answers.clear();
          _clearProgress();
          setState(() {
            _currentIndex = 0;
            _correctCount = 0;
            _wrongCount = 0;
            _startTime = DateTime.now();
            _resetQuestion();
          });
          _checkFavorite();
        },
        onSubmit: () { Navigator.pop(ctx); _finish(); },
        correctCount: _correctCount,
        wrongCount: _wrongCount,
      ),
    );
  }

  @override
  void dispose() {
    // 退出时静默保存进度（fire-and-forget，不阻塞 UI）
    if (!_isWrongMode && !_isFavoriteMode) {
      _saveProgress();
    }
    super.dispose();
  }

  Future<void> _finish() async {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    if (!_isWrongMode && !_isFavoriteMode) {
      await _clearProgress(); // 交卷完成，清除进度
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      await context.read<ExamProvider>().savePracticeRecord(
        bankId: widget.bankId,
        categoryId: widget.categoryId,
        practiceType: widget.practiceType,
        correctCount: _correctCount,
        wrongCount: _wrongCount,
        totalCount: _correctCount + _wrongCount,
        duration: duration,
      );
      // 完成练习，上报
      VisitReportService(AuthStorage()).reportPracticeComplete(
        pagePath: 'practice/${widget.bankId}',
        bankId: widget.bankId,
      );
    }
    if (mounted) {
      AppDialog.show(
        context: context,
        barrierDismissible: false,
        title: '练习完成',
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('总题', '${_correctCount + _wrongCount}'),
              _statItem('正确', '$_correctCount', AppColors.primary),
              _statItem('错误', '$_wrongCount', AppColors.wrongRed),
            ],
          ),
        ),
        actions: [
          AppDialogAction(
            text: '确定',
            isDefault: true,
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
          ),
        ],
      );
    }
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _loadQuestions, icon: const Icon(Icons.refresh, size: 18), label: const Text('重试')),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  String _stripHtml(String html) {
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

// ──────────── 答题记录 ────────────

class _QuestionAnswer {
  final String userAnswer;
  final bool isCorrect;
  const _QuestionAnswer(this.userAnswer, this.isCorrect);
}

// ──────────── 答题卡 Sheet ────────────

class _QuestionNavSheet extends StatelessWidget {
  final int total;
  final int current;
  final void Function(int) onSelect;
  final VoidCallback onRedo;
  final VoidCallback onSubmit;
  final int correctCount;
  final int wrongCount;

  const _QuestionNavSheet({
    required this.total,
    required this.current,
    required this.onSelect,
    required this.onRedo,
    required this.onSubmit,
    required this.correctCount,
    required this.wrongCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Text('答题卡', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
          const SizedBox(height: 12),
          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend('答对', AppColors.primary),
              const SizedBox(width: 20),
              _legend('答错', AppColors.wrongRed),
              const SizedBox(width: 20),
              _legend('未答', const Color(0xFFF0F0F0), textColor: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          // 题目格
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(total, (i) {
                  final isCurrent = i == current;
                  return GestureDetector(
                    onTap: () => onSelect(i),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary : const Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                        border: isCurrent ? null : Border.all(color: const Color(0xFFD9D9D9)),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isCurrent ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onRedo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('重做', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onSubmit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('提交', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color dotColor, {Color? textColor}) {
    return Row(
      children: [
        Container(width: 13, height: 13, decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: textColor ?? AppColors.textSecondary)),
      ],
    );
  }
}

// ──────────── Section Label ────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
