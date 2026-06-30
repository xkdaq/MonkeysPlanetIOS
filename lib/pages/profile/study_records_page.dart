import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/exam_provider.dart';
import '../../models/practice_record.dart';

class StudyRecordsPage extends StatefulWidget {
  const StudyRecordsPage({super.key});

  @override
  State<StudyRecordsPage> createState() => _StudyRecordsPageState();
}

class _StudyRecordsPageState extends State<StudyRecordsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('学习记录', style: TextStyle(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, exam, _) {
          if (exam.recordsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            );
          }

          if (exam.recordsError != null) {
            return _buildError(exam);
          }

          final records = exam.records;
          if (records == null || records.list.isEmpty) {
            return _buildEmpty(exam);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => exam.loadRecords(),
            child: CustomScrollView(
              slivers: [
                // 顶部统计 Banner
                SliverToBoxAdapter(child: _buildStatsBanner(records)),

                // 列表标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Text(
                          '练习记录',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${records.total}次',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 记录列表
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildRecordCard(records.list[i]),
                      childCount: records.list.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsBanner(PracticeRecordPage records) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07C160), Color(0xFF05A04E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          children: [
            _bannerStat('练习次数', '${records.total}'),
            _bannerDivider(),
            _bannerStat('总题数', '${records.totalQuestions}'),
            _bannerDivider(),
            _bannerStat('答对题数', '${records.totalCorrect}'),
            _bannerDivider(),
            _bannerStat('学习时长', records.totalDurationText),
          ],
        ),
      ),
    );
  }

  Widget _bannerStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerDivider() {
    return Container(
      width: 0.5,
      height: 32,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildRecordCard(PracticeRecord record) {
    final Color accuracyColor = record.accuracy >= 80
        ? AppColors.primary
        : record.accuracy >= 60
            ? const Color(0xFFF59E0B)
            : AppColors.wrongRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧彩色精度条
              Container(width: 4, color: accuracyColor),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 题库名 + 练习类型标签
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.bankName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              record.practiceTypeName,
                              style: const TextStyle(fontSize: 11, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.createTime,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                      const SizedBox(height: 12),

                      // 底部统计行
                      Row(
                        children: [
                          // 答题数
                          _chip(Icons.quiz_outlined, '${record.correctCount}/${record.totalCount} 题', AppColors.textSecondary),
                          const SizedBox(width: 12),
                          // 用时
                          _chip(Icons.timer_outlined, record.durationText, AppColors.textSecondary),
                          const Spacer(),
                          // 正确率 pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accuracyColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${record.accuracy}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accuracyColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildEmpty(ExamProvider exam) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.history_rounded, size: 40, color: Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无学习记录',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            '完成练习并点击「交卷」后，\n记录会自动保存到这里',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.6),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => exam.loadRecords(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.bgDivider),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('刷新', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ExamProvider exam) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(
            exam.recordsError!,
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => exam.loadRecords(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
