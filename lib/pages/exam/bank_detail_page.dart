import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/bank.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../profile/login_page.dart';
import 'practice_page.dart';
import 'question_list_page.dart';

/// 题库详情页（参考 Android 版 BankDetailActivity）
class BankDetailPage extends StatefulWidget {
  final Bank bank;

  const BankDetailPage({super.key, required this.bank});

  @override
  State<BankDetailPage> createState() => _BankDetailPageState();
}

class _BankDetailPageState extends State<BankDetailPage> {
  int? _selectedCategoryId;
  int? _selectedSubjectId;
  List<Category> _topLevelCategories = [];
  List<Category> _currentSubCategories = [];

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
      appBar: AppBar(
        title: Text(
          widget.bank.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, _) {
          return Column(
            children: [
              // 题库描述
              if (widget.bank.description != null &&
                  widget.bank.description!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primaryLight,
                  child: Text(
                    widget.bank.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),

              // 顶部快捷入口按钮
              _buildQuickActions(),

              const Divider(height: 1),

              // 分类区域
              Expanded(
                child: _buildCategorySection(examProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 快捷入口按钮（顺序练习/随机练习/错题练习/收藏练习）
  Widget _buildQuickActions() {
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.sort,
            label: '顺序练习',
            onTap: () => _startPractice(1),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.shuffle,
            label: '随机练习',
            onTap: () => _startPractice(2),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.cancel_outlined,
            label: '错题练习',
            color: AppColors.wrongRed,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestionListPage(mode: 'wrong', bankId: widget.bank.id),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.star_border,
            label: '收藏练习',
            color: AppColors.warningOrange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestionListPage(mode: 'favorite', bankId: widget.bank.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 分类列表区域
  Widget _buildCategorySection(ExamProvider examProvider) {
    if (examProvider.categoriesLoading) {
      return const LoadingIndicator(message: '加载分类...');
    }

    if (examProvider.categoriesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(examProvider.categoriesError!,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => examProvider.loadCategories(widget.bank.id),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final categories = examProvider.categories;
    if (categories.isEmpty) {
      return const EmptyState(message: '暂无分类');
    }

    // 构建分类树：找出顶层分类
    if (_topLevelCategories.isEmpty) {
      _topLevelCategories = categories.where((c) => c.parentId == null || (c.parentId != null && c.parentId == 0)).toList();
      if (_topLevelCategories.isNotEmpty && _selectedSubjectId == null) {
        _selectedSubjectId = _topLevelCategories.first.id;
        _updateSubCategories(categories);
      }
    }

    // 判断是否有三级结构（有顶层分类且有子分类的子分类）
    final hasThreeLevel = _checkHasThreeLevel(categories);

    if (hasThreeLevel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶层分类 Tab（科目）
          Container(
            height: 44,
            color: AppColors.bgWhite,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _topLevelCategories.length,
              itemBuilder: (context, index) {
                final cat = _topLevelCategories[index];
                final isSelected = cat.id == _selectedSubjectId;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSubjectId = cat.id;
                      _selectedCategoryId = null;
                      _updateSubCategories(categories);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 子分类列表
          Expanded(
            child: _currentSubCategories.isEmpty
                ? const EmptyState(message: '暂无子分类')
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _currentSubCategories.length,
                    itemBuilder: (context, index) {
                      final cat = _currentSubCategories[index];
                      final isSelected = cat.id == _selectedCategoryId;
                      final isLeaf = cat.children == null || cat.children!.isEmpty;

                      // 如果有子分类，展示可展开项
                      if (!isLeaf) {
                        return _CategoryGroup(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () => _onCategoryTap(cat, categories),
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        elevation: 0,
                        color: isSelected ? AppColors.primaryLight : AppColors.bgWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.bgDivider,
                            width: isSelected ? 1 : 0.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _onCategoryTap(cat, categories),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${cat.children?.length ?? 0}',
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // 二级结构：直接展示列表
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = cat.id == _selectedCategoryId;
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          elevation: 0,
          color: isSelected ? AppColors.primaryLight : AppColors.bgWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.bgDivider,
              width: isSelected ? 1 : 0.5,
            ),
          ),
          child: InkWell(
            onTap: () => _onCategoryTap(cat, categories),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _checkHasThreeLevel(List<Category> categories) {
    for (final cat in categories) {
      if (cat.children != null && cat.children!.isNotEmpty) {
        for (final child in cat.children!) {
          if (child.children != null && child.children!.isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _updateSubCategories(List<Category> categories) {
    if (_selectedSubjectId != null) {
      final subject = categories.where((c) => c.id == _selectedSubjectId).firstOrNull;
      if (subject != null) {
        _currentSubCategories = subject.children ?? [];
      }
    }
  }

  void _onCategoryTap(Category category, List<Category> allCategories) {
    // 如果是非叶子节点，展开
    if (category.children != null && category.children!.isNotEmpty) {
      setState(() {
        _selectedCategoryId = category.id;
        _currentSubCategories = category.children!;
      });
      return;
    }

    // 叶子节点，开始练习
    _startPractice(3, categoryId: category.id);
  }

  void _startPractice(int type, {int? categoryId}) {
    // 检查登录
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticePage(
          bankId: widget.bank.id,
          categoryId: categoryId,
          practiceType: type,
        ),
      ),
    );
  }
}

/// 快捷操作按钮
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: btnColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: btnColor, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: btnColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 分类分组（有子分类的节点）
class _CategoryGroup extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryGroup({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: AppColors.bgWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.bgDivider,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${category.children?.length ?? 0} 个章节',
                style: const TextStyle(color: AppColors.textHint, fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
