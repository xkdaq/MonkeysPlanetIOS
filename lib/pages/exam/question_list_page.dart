import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/question.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'practice_page.dart';

/// 错题/收藏列表页（参考 Android 版 QuestionListActivity）
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

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);

    final examProvider = context.read<ExamProvider>();
    if (widget.mode == 'wrong') {
      await examProvider.loadWrongQuestions();
      if (mounted) {
        setState(() {
          _questions = examProvider.wrongQuestions;
          _isLoading = false;
        });
      }
    } else {
      await examProvider.loadFavoriteQuestions();
      if (mounted) {
        setState(() {
          _questions = examProvider.favoriteQuestions;
          _isLoading = false;
        });
      }
    }
  }

  String get _title => widget.mode == 'wrong' ? '错题列表' : '收藏列表';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    // 统计
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: AppColors.bgGray,
                      child: Row(
                        children: [
                          Text(
                            '共 ${_questions.length} 题',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PracticePage(
                                    bankId: widget.bankId ?? 0,
                                    practiceType: 1,
                                    mode: widget.mode,
                                  ),
                                ),
                              ).then((_) => _loadQuestions());
                            },
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('开始练习'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // 题目列表
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadQuestions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            return _QuestionPreviewCard(
                              index: index + 1,
                              question: question,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PracticePage(
                                      bankId: widget.bankId ?? 0,
                                      practiceType: 1,
                                      mode: widget.mode,
                                      startIndex: index,
                                    ),
                                  ),
                                ).then((_) => _loadQuestions());
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// 题目预览卡片
class _QuestionPreviewCard extends StatelessWidget {
  final int index;
  final Question question;
  final VoidCallback onTap;

  const _QuestionPreviewCard({
    required this.index,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.bgDivider, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 序号
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stripHtml(question.content),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Tag(question.typeName),
                        const SizedBox(width: 8),
                        if (question.answer != null)
                          Text(
                            '答案: ${question.answer}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
