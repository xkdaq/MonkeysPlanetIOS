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
import 'settings_page.dart';
import '../../widgets/app_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgWhite,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // 用户信息卡片
              _buildUserCard(context, authProvider),
              const SizedBox(height: 10),

              // 账户功能菜单（仅登录后显示）
              if (authProvider.isLoggedIn) ...[
                _buildMenuCard([
                  _MenuItem(
                    imagePath: 'assets/images/mine-bind-phone.png',
                    label: '绑定手机号',
                    badge: authProvider.userInfo?.phone != null ? '已绑定' : '未绑定',
                    badgeBound: authProvider.userInfo?.phone != null,
                    onTap: () => _navigate(context, const BindPhonePage()),
                  ),
                  if (authProvider.userInfo?.phone != null)
                    _MenuItem(
                      imagePath: 'assets/images/mine-change-pwd.png',
                      label: '修改密码',
                      onTap: () => _navigate(context, const ChangePasswordPage()),
                    ),
                  _MenuItem(
                    imagePath: 'assets/images/mine-study.png',
                    label: '学习记录',
                    onTap: () => _navigate(context, const StudyRecordsPage()),
                  ),
                ]),
                const SizedBox(height: 10),
              ],

              // 通用菜单
              _buildMenuCard([
                _MenuItem(
                  imagePath: 'assets/images/mine-setting.png',
                  label: '设置',
                  onTap: () => _navigate(context, const SettingsPage()),
                ),
                _MenuItem(
                  imagePath: 'assets/images/mine-about-us.png',
                  label: '关于我们',
                  onTap: () => _navigate(context, const AboutPage()),
                ),
                _MenuItem(
                  imagePath: 'assets/images/mine-hao-ping.png',
                  label: '问题反馈',
                  onTap: () => _navigate(context, const FeedbackPage()),
                ),
              ]),

              // 退出登录
              if (authProvider.isLoggedIn) ...[
                const SizedBox(height: 10),
                _buildLogoutButton(context, authProvider),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: authProvider.isLoggedIn
          ? _buildLoggedInUser(context, authProvider)
          : _buildNotLoggedIn(context),
    );
  }

  Widget _buildLoggedInUser(BuildContext context, AuthProvider authProvider) {
    return Row(
      children: [
        // 头像
        GestureDetector(
          onTap: () => _navigate(context, const EditProfilePage()),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgGray,
              boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: ClipOval(
              child: authProvider.userInfo?.avatarUrl?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: authProvider.userInfo!.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Image.asset('assets/images/default-avatar.png', fit: BoxFit.cover),
                      errorWidget: (ctx, url, err) => Image.asset('assets/images/default-avatar.png', fit: BoxFit.cover),
                    )
                  : Image.asset('assets/images/default-avatar.png', fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // 用户信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      authProvider.displayName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (authProvider.userInfo?.gender == 1) ...[
                    const SizedBox(width: 5),
                    Image.asset('assets/images/icon_nan.png', width: 16, height: 16),
                  ] else if (authProvider.userInfo?.gender == 2) ...[
                    const SizedBox(width: 5),
                    Image.asset('assets/images/icon_nv.png', width: 16, height: 16),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${authProvider.userInfo?.username ?? authProvider.userInfo?.id ?? ''}',
                style: const TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            ],
          ),
        ),
        // 编辑按钮
        GestureDetector(
          onTap: () => _navigate(context, const EditProfilePage()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x1407C160),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('编辑', style: TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        ClipOval(
          child: Image.asset('assets/images/default-avatar.png', width: 60, height: 60, fit: BoxFit.cover),
        ),
        const SizedBox(height: 10),
        const Text('登录后享受更多功能', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 11),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
            child: const Text('立即登录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildMenuItem(item),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 0, color: Color(0xFFF0F0F0)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: Image.asset(item.imagePath, width: 22, height: 22, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
            ),
            if (item.badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: item.badgeBound == true ? const Color(0x1407C160) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.badge!,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.badgeBound == true ? AppColors.primary : AppColors.textHint,
                  ),
                ),
              ),
            Image.asset('assets/images/mine-arrow-right.png', width: 16, height: 16, color: const Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context, authProvider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: const Center(
          child: Text('退出登录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFFF4D4F))),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    AppDialog.show(
      context: context,
      title: '退出登录',
      message: '确定要退出登录吗？',
      actions: [
        AppDialogAction(
          text: '取消',
          style: AppDialogActionStyle.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          text: '退出',
          style: AppDialogActionStyle.destructive,
          onPressed: () {
            Navigator.pop(context);
            authProvider.logout();
          },
        ),
      ],
    );
  }
}

class _MenuItem {
  final String imagePath;
  final String label;
  final String? badge;
  final bool? badgeBound;
  final VoidCallback onTap;

  _MenuItem({
    required this.imagePath,
    required this.label,
    this.badge,
    this.badgeBound,
    required this.onTap,
  });
}
