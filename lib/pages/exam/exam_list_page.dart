import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/bank.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'bank_detail_page.dart';

/// 题库列表页（参考 Android 版 ExamFragment）
class ExamListPage extends StatefulWidget {
  const ExamListPage({super.key});

  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  @override
  void initState() {
    super.initState();
    // 延迟加载，等 Provider 初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadBanks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '题库',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, _) {
          if (examProvider.banksLoading) {
            return const LoadingIndicator(message: '加载题库中...');
          }

          if (examProvider.banksError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    examProvider.banksError!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => examProvider.loadBanks(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (examProvider.banks.isEmpty) {
            return const EmptyState(
              message: '暂无题库',
              icon: Icons.library_books_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () => examProvider.loadBanks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: examProvider.banks.length,
              itemBuilder: (context, index) {
                return _BankCard(
                  bank: examProvider.banks[index],
                  onTap: () {
                    final bank = examProvider.banks[index];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BankDetailPage(bank: bank),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// 题库卡片（参考 Android 版 item_bank.xml）
class _BankCard extends StatelessWidget {
  final Bank bank;
  final VoidCallback onTap;

  const _BankCard({required this.bank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bgDivider, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 封面图标
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.library_books,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              // 文字区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (bank.description != null && bank.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bank.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (bank.questionCount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${bank.questionCount} 题',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
