import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

/// 学习记录页（参考 Android 版 StudyRecordsActivity）
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
        builder: (context, examProvider, _) {
          if (examProvider.recordsLoading) {
            return const LoadingIndicator(message: '加载记录中...');
          }

          if (examProvider.recordsError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(examProvider.recordsError!,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => examProvider.loadRecords(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final records = examProvider.records;
          if (records == null || records.list.isEmpty) {
            return const EmptyState(
              message: '暂无学习记录',
              icon: Icons.history,
            );
          }

          return RefreshIndicator(
            onRefresh: () => examProvider.loadRecords(),
            child: Column(
              children: [
                // 统计概览
                Container(
                  color: AppColors.bgWhite,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('总题数', '${records.totalQuestions}'),
                      _statItem('正确数', '${records.totalCorrect}', AppColors.correctGreen),
                      _statItem('练习时长', records.totalDurationText),
                      _statItem('总次数', '${records.total}'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 记录列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: records.list.length,
                    itemBuilder: (context, index) {
                      final record = records.list[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                              color: AppColors.bgDivider, width: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.bankName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _infoTag(record.practiceTypeName, AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          record.createTime,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '正确 ${record.correctCount}/${record.totalCount}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: record.accuracy >= 70
                                                ? AppColors.correctGreen
                                                : AppColors.wrongRed,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '正确率 ${record.accuracy}%',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '用时 ${record.durationText}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _infoTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}
