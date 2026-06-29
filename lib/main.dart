import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'pages/main_tabs.dart';
import 'pages/profile/login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/exam_provider.dart';
import 'services/auth_event.dart';
import 'services/auth_storage.dart';

// 全局导航 Key，供 HTTP 拦截器在 Token 过期时跳转登录页使用
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.bgWhite,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final authStorage = AuthStorage();

  // 登录过期时：清除 AuthProvider 状态 + 回到主页再弹出登录页（避免黑屏）
  AuthEvent.onExpired(() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Provider.of<AuthProvider>(ctx, listen: false).logout();
    }
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => route.isFirst, // 保留 MainTabs 作为根路由，返回不黑屏
    );
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authStorage)),
        ChangeNotifierProvider(create: (_) => ExamProvider(authStorage)),
      ],
      child: const MonkeysPlanetApp(),
    ),
  );
}

class MonkeysPlanetApp extends StatelessWidget {
  const MonkeysPlanetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '猴哥星球',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 参考 Android 版 themes.xml：Material3 Light + NoActionBar
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.bgWhite,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.bgDivider,
          thickness: 0.5,
          space: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 48),
            textStyle: const TextStyle(fontSize: 16),
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        ),
      ),
      navigatorKey: navigatorKey,
      home: const MainTabs(),
    );
  }
}
