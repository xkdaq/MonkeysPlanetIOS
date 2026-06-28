import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'bind_phone_page.dart';
import 'change_password_page.dart';
import 'study_records_page.dart';
import 'about_page.dart';
import 'feedback_page.dart';

/// 个人中心页 / 我的（参考 Android 版 ProfileFragment）
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '我的',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return ListView(
            children: [
              // 用户信息卡片
              _buildUserCard(context, authProvider),
              const SizedBox(height: 8),

              // 账户菜单
              _buildMenuSection(context, '账户', [
                _MenuItemData(
                  icon: Icons.phone_android,
                  label: '绑定手机号',
                  badge: authProvider.userInfo?.phone != null ? '已绑定' : '未绑定',
                  onTap: () => _navigate(context, const BindPhonePage()),
                ),
                if (authProvider.userInfo?.phone != null)
                  _MenuItemData(
                    icon: Icons.lock_outline,
                    label: '修改密码',
                    onTap: () => _navigate(context, const ChangePasswordPage()),
                  ),
                _MenuItemData(
                  icon: Icons.assignment_outlined,
                  label: '学习记录',
                  onTap: () => _navigate(context, const StudyRecordsPage()),
                ),
              ]),

              const SizedBox(height: 8),

              // 通用菜单
              _buildMenuSection(context, '其他', [
                _MenuItemData(
                  icon: Icons.info_outline,
                  label: '关于我们',
                  onTap: () => _navigate(context, const AboutPage()),
                ),
                _MenuItemData(
                  icon: Icons.feedback_outlined,
                  label: '问题反馈',
                  onTap: () => _navigate(context, const FeedbackPage()),
                ),
              ]),

              // 退出登录按钮
              if (authProvider.isLoggedIn)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgWhite,
                      foregroundColor: AppColors.wrongRed,
                      side: const BorderSide(color: AppColors.wrongRed),
                    ),
                    child: const Text('退出登录'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 用户信息卡片（已登录/未登录两种状态）
  Widget _buildUserCard(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isLoggedIn) {
      // 已登录状态
      return Container(
        color: AppColors.bgWhite,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 头像
            GestureDetector(
              onTap: () => _navigate(context, const EditProfilePage()),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.bgGray,
                backgroundImage: authProvider.userInfo?.avatarUrl != null &&
                        authProvider.userInfo!.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(authProvider.userInfo!.avatarUrl!)
                    : null,
                child: authProvider.userInfo?.avatarUrl == null ||
                        authProvider.userInfo!.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 32, color: AppColors.textHint)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authProvider.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.displayId,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // 编辑按钮
            GestureDetector(
              onTap: () => _navigate(context, const EditProfilePage()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.bgDivider),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '编辑资料',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 未登录状态
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.bgGray,
            child: const Icon(Icons.person, size: 36, color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          const Text(
            '欢迎来到猴哥星球',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(180, 44),
            ),
            child: const Text('立即登录'),
          ),
        ],
      ),
    );
  }

  /// 带标题的菜单区域
  Widget _buildMenuSection(
      BuildContext context, String title, List<_MenuItemData> items) {
    if (items.isEmpty) return const SizedBox();
    return Container(
      color: AppColors.bgWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ...items.map((item) => _buildMenuItem(context, item)),
        ],
      ),
    );
  }

  /// 单个菜单项（参考 Android 版 item_profile_menu.xml）
  Widget _buildMenuItem(BuildContext context, _MenuItemData item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        color: AppColors.bgWhite,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(item.icon, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
                ],
              ),
            ),
            const Divider(height: 1, indent: 50),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            child: const Text('确定', style: TextStyle(color: AppColors.wrongRed)),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });
}
