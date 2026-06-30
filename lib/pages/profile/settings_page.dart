import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
            children: [
              // 通知设置
              _sectionLabel('通知设置'),
              _buildCard([
                _switchRow(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFF5B8DEF),
                  label: '推送通知',
                  value: _pushEnabled,
                  onChanged: (v) => setState(() => _pushEnabled = v),
                ),
              ]),
              const SizedBox(height: 16),

              // 通用
              _sectionLabel('通用'),
              _buildCard([
                _arrowRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFFF7A45),
                  label: '清除缓存',
                  trailing: '< 1 MB',
                  onTap: () => _clearCache(context),
                ),
              ]),
              const SizedBox(height: 16),

              // 账号（仅登录后）
              if (auth.isLoggedIn) ...[
                _sectionLabel('账号'),
                _buildCard([
                  _arrowRow(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    label: '账号注销',
                    onTap: () => _confirmDeleteAccount(context, auth),
                  ),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key < children.length - 1)
                Container(height: 0.5, color: AppColors.bgDivider, margin: const EdgeInsets.only(left: 56)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _arrowRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(trailing, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
              ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('清除缓存'),
        content: const Text('清除缓存不会影响您的账号数据，确定继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缓存已清除'), duration: Duration(seconds: 2)));
            },
            child: const Text('清除', style: TextStyle(color: Color(0xFFFF7A45))),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('注销账号'),
        content: const Text('注销后账号数据将永久删除，无法恢复。确定要注销吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('注销功能即将上线'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('注销', style: TextStyle(color: Color(0xFFFF4D4F))),
          ),
        ],
      ),
    );
  }
}
