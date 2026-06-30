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
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }

          if (exam.recordsError != null) {
            return _buildError(context, exam);
          }

          final records = exam.records;
          if (records == null || records.list.isEmpty) {
            return _buildEmpty(context, exam);
          }

          return RefreshIndicator(
            onRefresh: () => exam.loadRecords(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSummaryCard(records)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
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

  Widget _buildSummaryCard(PracticeRecordPage records) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          _summaryItem('练习次数', '${records.total}', null),
          _summaryDivider(),
          _summaryItem('答题总数', '${records.totalQuestions}', null),
          _summaryDivider(),
          _summaryItem('答对题数', '${records.totalCorrect}', AppColors.primary),
          _summaryDivider(),
          _summaryItem('练习时长', records.totalDurationText, null),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color? valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(width: 0.5, height: 32, color: AppColors.bgDivider);
  }

  Widget _buildRecordCard(PracticeRecord record) {
    final accuracyColor = record.accuracy >= 80
        ? AppColors.primary
        : record.accuracy >= 60
            ? const Color(0xFFF59E0B)
            : AppColors.wrongRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：题库名 + 练习类型标签 + 时间
          Row(
            children: [
              Expanded(
                child: Text(
                  record.bankName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                child: Text(record.practiceTypeName, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(record.createTime, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 12),

          // 底部：统计数据
          Row(
            children: [
              _statChip(Icons.quiz_outlined, '${record.totalCount} 题', AppColors.textSecondary),
              const SizedBox(width: 10),
              _statChip(Icons.check_circle_outline, '${record.correctCount} 对', AppColors.primary),
              const SizedBox(width: 10),
              _statChip(Icons.timer_outlined, record.durationText, AppColors.textSecondary),
              const Spacer(),
              // 正确率圆形指示
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: record.accuracy / 100,
                      strokeWidth: 3,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
                    ),
                    Text(
                      '${record.accuracy}%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accuracyColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, ExamProvider exam) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.history, size: 38, color: Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 16),
          const Text('暂无学习记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('完成练习并点击「交卷」后，\n记录会自动保存到这里',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.6)),
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

  Widget _buildError(BuildContext context, ExamProvider exam) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(exam.recordsError!, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => exam.loadRecords(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
