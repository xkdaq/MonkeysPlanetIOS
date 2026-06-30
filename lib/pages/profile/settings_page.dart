import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
    AppDialog.show(
      context: context,
      title: '清除缓存',
      message: '清除缓存不会影响您的账号数据，确定继续吗？',
      actions: [
        AppDialogAction(
          text: '取消',
          style: AppDialogActionStyle.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          text: '清除',
          style: AppDialogActionStyle.destructive,
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('缓存已清除'), duration: Duration(seconds: 2)),
            );
          },
        ),
      ],
    );
  }

}
