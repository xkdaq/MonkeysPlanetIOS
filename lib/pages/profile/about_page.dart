import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/legal_urls.dart';

/// 关于我们页（参考 Android 版 AboutActivity）
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('关于我们', style: TextStyle(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          // App 图标
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.public, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '猴哥星球',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 32),

          // 链接
          _buildLinkItem(
            context,
            '用户服务协议',
            LegalUrls.userAgreement,
          ),
          const Divider(indent: 16),
          _buildLinkItem(
            context,
            '隐私政策',
            LegalUrls.privacyPolicy,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, String title, String url) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.open_in_new, color: AppColors.textHint, size: 18),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开: $url')),
        );
      },
    );
  }
}
