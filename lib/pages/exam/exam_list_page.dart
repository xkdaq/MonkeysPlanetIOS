import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../models/bank.dart';
import '../../providers/exam_provider.dart';
import '../../services/auth_storage.dart';
import '../../services/visit_report_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'bank_detail_page.dart';

class ExamListPage extends StatefulWidget {
  const ExamListPage({super.key});

  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadBanks();
      // 上报题库首页访问
      VisitReportService(AuthStorage()).reportExamPageView(pagePath: 'exam/list');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '题库',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.bgWhite,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, _) {
          if (examProvider.banksLoading) {
            return const LoadingIndicator(message: '题库加载中...');
          }

          if (examProvider.banksError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(examProvider.banksError!, style: const TextStyle(color: AppColors.textSecondary)),
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
            return const EmptyState(message: '暂无题库数据', icon: Icons.library_books_outlined);
          }

          return RefreshIndicator(
            onRefresh: () => examProvider.loadBanks(),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // 标题卡片
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '选择题库',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '进入题库后再查看分类、练习和收藏',
                        style: TextStyle(fontSize: 13, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                // 题库列表
                ...examProvider.banks.map((bank) => _BankCard(
                  bank: bank,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BankDetailPage(bank: bank)),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  final Bank bank;
  final VoidCallback onTap;

  const _BankCard({required this.bank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: bank.coverImage != null && bank.coverImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: bank.coverImage!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 14),
            // 文字区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bank.description?.isNotEmpty == true ? bank.description! : '暂无题库描述',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0x1A07C160),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text('题', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),
    );
  }
}
