import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_storage.dart';
import '../services/version_check_service.dart';
import '../widgets/update_dialog.dart';
import 'exam/exam_list_page.dart';
import 'profile/profile_page.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ExamListPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 进主页后检查版本更新
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVersion());
  }

  void _checkVersion() {
    VersionCheckService(AuthStorage()).check().then((info) {
      if (!mounted || info == null) return;

      if (info.isForced) {
        // 强制更新：弹框不可关闭，用户必须点更新
        UpdateDialog.show(context: context, info: info).then((shouldUpdate) {
          if (shouldUpdate == true) {
            UpdateDialog.openDownloadUrl(info.downloadUrl);
          }
        });
      } else {
        // 可选更新：用户可忽略
        UpdateDialog.show(context: context, info: info).then((shouldUpdate) {
          if (shouldUpdate == true) {
            UpdateDialog.openDownloadUrl(info.downloadUrl);
          }
        });
      }
    });
    // 检查失败静默处理
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.bgDivider, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.bgWhite,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF999999),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset('assets/images/exam.png', width: 24, height: 24),
              activeIcon: Image.asset('assets/images/exam-active.png', width: 24, height: 24),
              label: '题库',
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/images/mine.png', width: 24, height: 24),
              activeIcon: Image.asset('assets/images/mine_selected.png', width: 24, height: 24),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
