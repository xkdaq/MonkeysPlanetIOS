import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/bank.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';
import '../profile/login_page.dart';
import 'practice_page.dart';
import 'question_list_page.dart';

class BankDetailPage extends StatefulWidget {
  final Bank bank;

  const BankDetailPage({super.key, required this.bank});

  @override
  State<BankDetailPage> createState() => _BankDetailPageState();
}

class _BankDetailPageState extends State<BankDetailPage> {
  int? _selectedSubjectId;
  List<Category> _currentSubCategories = [];
  int? _lastLoadedBankId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadCategories(widget.bank.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ExamProvider>(
          builder: (context, examProvider, _) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBankHeader(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildQuickActions(),
                  ),
                  _buildCategorySection(examProvider),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBankHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new, size: 12, color: AppColors.primary),
                SizedBox(width: 3),
                Text('题库列表', style: TextStyle(fontSize: 13, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.bank.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            widget.bank.description?.isNotEmpty == true ? widget.bank.description! : '选择分类或练习方式开始刷题',
            style: const TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionItem('assets/images/exam-order.png', '顺序练习', const Color(0x1A07C160), () => _startPractice(1)),
        const SizedBox(width: 8),
        _buildActionItem('assets/images/exam-random.png', '随机练习', const Color(0x1A10B981), () => _startPractice(2)),
        const SizedBox(width: 8),
        _buildActionItem('assets/images/exam-wrong.png', '错题练习', const Color(0x1A3B82F6), () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => QuestionListPage(mode: 'wrong', bankId: widget.bank.id),
          ));
        }),
        const SizedBox(width: 8),
        _buildActionItem('assets/images/exam-favorite.png', '我的收藏', const Color(0x1AF59E0B), () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => QuestionListPage(mode: 'favorite', bankId: widget.bank.id),
          ));
        }),
      ],
    );
  }

  Widget _buildActionItem(String imagePath, String label, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(ExamProvider examProvider) {
    if (examProvider.categoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      );
    }

    if (examProvider.categoriesError != null) {
      return _buildErrorCard(examProvider);
    }

    if (examProvider.categoriesBankId != widget.bank.id) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      );
    }

    final categories = examProvider.categories;
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('暂无分类数据', style: TextStyle(color: AppColors.textHint))),
      );
    }

    final topLevelCategories = categories.where((c) => c.parentId == null || c.parentId == 0).toList();

    if (_lastLoadedBankId != widget.bank.id) {
      _lastLoadedBankId = widget.bank.id;
      _selectedSubjectId = topLevelCategories.isNotEmpty ? topLevelCategories.first.id : null;
      _currentSubCategories = [];
      if (_selectedSubjectId != null) _updateSubCategories(categories, topLevelCategories);
    }

    final hasThreeLevel = _checkHasThreeLevel(categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // 科目 Tab（三级结构才显示）
        if (hasThreeLevel && topLevelCategories.isNotEmpty) ...[
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: topLevelCategories.length,
              itemBuilder: (_, i) {
                final cat = topLevelCategories[i];
                final isSelected = cat.id == _selectedSubjectId;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedSubjectId = cat.id;
                    _currentSubCategories = [];
                    _updateSubCategories(categories, topLevelCategories);
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0x1407C160) : AppColors.bgWhite,
                      border: Border.all(
                        color: isSelected ? const Color(0x7307C160) : const Color(0xFFE8E8E8),
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: Center(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 分类列表卡片
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: '题库分类'),
              const SizedBox(height: 12),
              _buildCategoryList(hasThreeLevel ? _currentSubCategories : topLevelCategories),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(List<Category> cats) {
    if (cats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('暂无分类数据', style: TextStyle(color: AppColors.textHint))),
      );
    }
    return Column(
      children: cats.asMap().entries.map((entry) {
        final i = entry.key;
        final cat = entry.value;
        final hasChildren = cat.children != null && cat.children!.isNotEmpty;
        return Padding(
          padding: EdgeInsets.only(bottom: i < cats.length - 1 ? 12 : 0),
          child: _CategoryItem(
            category: cat,
            hasChildren: hasChildren,
            onTap: () {
              if (hasChildren) {
                setState(() => _currentSubCategories = cat.children!);
              } else {
                _startPractice(3, categoryId: cat.id);
              }
            },
            onChildTap: (child) => _startPractice(3, categoryId: child.id),
          ),
        );
      }).toList(),
    );
  }

  bool _checkHasThreeLevel(List<Category> categories) {
    for (final cat in categories) {
      if (cat.children != null) {
        for (final child in cat.children!) {
          if (child.children != null && child.children!.isNotEmpty) return true;
        }
      }
    }
    return false;
  }

  Widget _buildErrorCard(ExamProvider examProvider) {
    final msg = examProvider.categoriesError ?? '获取分类失败';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          // 三层同心圆 + 图标
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                ),
                Container(
                  width: 58, height: 58,
                  decoration: const BoxDecoration(color: Color(0xFFEEEEEE), shape: BoxShape.circle),
                ),
                const Icon(Icons.wifi_off_rounded, size: 30, color: Color(0xFFBBBBBB)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            msg,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text('请检查网络连接后重试', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => examProvider.loadCategories(widget.bank.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('重新加载', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateSubCategories(List<Category> categories, List<Category> topLevel) {
    final subject = topLevel.where((c) => c.id == _selectedSubjectId).firstOrNull;
    if (subject != null) _currentSubCategories = subject.children ?? [];
  }

  void _startPractice(int type, {int? categoryId}) {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PracticePage(bankId: widget.bank.id, categoryId: categoryId, practiceType: type),
    ));
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 15,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final Category category;
  final bool hasChildren;
  final VoidCallback onTap;
  final void Function(Category child) onChildTap;

  const _CategoryItem({
    required this.category,
    required this.hasChildren,
    required this.onTap,
    required this.onChildTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasChildren ? null : onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: hasChildren
                    ? const Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                  ),
                  if (!hasChildren)
                    const Text('→', style: TextStyle(fontSize: 14, color: Color(0xFFCCCCCC))),
                ],
              ),
            ),
          ),
          if (hasChildren)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: category.children!.asMap().entries.map((e) {
                  final isLast = e.key == category.children!.length - 1;
                  final sub = e.value;
                  return GestureDetector(
                    onTap: () => onChildTap(sub),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(sub.name, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ),
                          const Text('→', style: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
