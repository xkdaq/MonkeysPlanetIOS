import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/question.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'practice_page.dart';

/// 错题/收藏列表页 — 按章节(categoryName)折叠展示
class QuestionListPage extends StatefulWidget {
  final String mode; // 'wrong' 或 'favorite'
  final int? bankId;

  const QuestionListPage({
    super.key,
    required this.mode,
    this.bankId,
  });

  @override
  State<QuestionListPage> createState() => _QuestionListPageState();
}

class _QuestionListPageState extends State<QuestionListPage> {
  List<Question> _questions = [];
  bool _isLoading = true;

  // 章节名 → 该章节下的题目列表（保持原始顺序）
  late List<_CategoryGroup> _groups;
  // 当前已展开的章节
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final provider = context.read<ExamProvider>();
    if (widget.mode == 'wrong') {
      await provider.loadWrongQuestions(bankId: widget.bankId);
      if (mounted) _apply(provider.wrongQuestions);
    } else {
      await provider.loadFavoriteQuestions(bankId: widget.bankId);
      if (mounted) _apply(provider.favoriteQuestions);
    }
  }

  void _apply(List<Question> qs) {
    _questions = qs;
    _groups = _buildGroups(qs);
    _expanded.clear();
    if (_groups.isNotEmpty) _expanded.add(_groups.first.name);
    setState(() => _isLoading = false);
  }

  List<_CategoryGroup> _buildGroups(List<Question> qs) {
    // 保持顺序：按题目出现顺序分组
    final order = <String>[];
    final map = <String, List<_IndexedQuestion>>{};

    for (var i = 0; i < qs.length; i++) {
      final q = qs[i];
      final key = q.categoryName?.trim().isNotEmpty == true ? q.categoryName! : '未分类';
      if (!map.containsKey(key)) {
        order.add(key);
        map[key] = [];
      }
      map[key]!.add(_IndexedQuestion(flatIndex: i, question: q));
    }

    return order.map((name) => _CategoryGroup(name: name, items: map[name]!)).toList();
  }

  String get _title => widget.mode == 'wrong' ? '错题列表' : '收藏列表';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _questions.isEmpty
              ? EmptyState(
                  message: widget.mode == 'wrong' ? '暂无错题' : '暂无收藏',
                  icon: widget.mode == 'wrong' ? Icons.check_circle_outline : Icons.star_outline,
                )
              : Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadQuestions,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                          itemCount: _groups.length,
                          itemBuilder: (_, i) => _buildGroupCard(_groups[i]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider, width: 0.5)),
      ),
      child: Row(
        children: [
          Text('共 ${_questions.length} 题', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PracticePage(
                  bankId: widget.bankId ?? 0,
                  practiceType: 1,
                  mode: widget.mode,
                ),
              ),
            ).then((_) => _loadQuestions()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('开始练习', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(_CategoryGroup group) {
    final isExpanded = _expanded.contains(group.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          // 章节头部
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) {
                _expanded.remove(group.name);
              } else {
                _expanded.add(group.name);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // 绿色左竖线
                  Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${group.items.length}题',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),

          // 题目列表
          if (isExpanded) ...[
            Container(height: 0.5, color: AppColors.bgDivider),
            ...group.items.asMap().entries.map((entry) {
              final localIdx = entry.key;
              final item = entry.value;
              final isLast = localIdx == group.items.length - 1;
              return _buildQuestionItem(item, localIdx + 1, isLast);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionItem(_IndexedQuestion item, int localIndex, bool isLast) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PracticePage(
            bankId: widget.bankId ?? 0,
            practiceType: 1,
            mode: widget.mode,
            startIndex: item.flatIndex,
          ),
        ),
      ).then((_) => _loadQuestions()),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 序号徽章
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '$localIndex',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 题型标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.question.typeName,
                      style: const TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _stripHtml(item.question.content),
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
}

class _CategoryGroup {
  final String name;
  final List<_IndexedQuestion> items;
  const _CategoryGroup({required this.name, required this.items});
}

class _IndexedQuestion {
  final int flatIndex; // 在完整列表中的位置，传给 PracticePage.startIndex
  final Question question;
  const _IndexedQuestion({required this.flatIndex, required this.question});
}
