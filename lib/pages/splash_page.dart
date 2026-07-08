import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_storage.dart';
import '../services/device_info_service.dart';
import 'main_tabs.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  late final AnimationController _exitCtrl;

  bool _authReady = false;
  bool _minTimeDone = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.7, curve: Curves.easeIn));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );

    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _logoCtrl.forward().then((_) => _textCtrl.forward());

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        _minTimeDone = true;
        _maybeNavigate();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
      _registerDevice(); // ★ 启动时并行注册设备（不阻塞导航）
    });
  }

  /// ★ 注册设备信息（不阻塞启动流程）
  void _registerDevice() {
    final authStorage = AuthStorage();
    DeviceInfoService(authStorage).register();
  }

  void _checkAuth() {
    if (!context.read<AuthProvider>().isLoading) {
      _authReady = true;
      _maybeNavigate();
    } else {
      _pollAuth();
    }
  }

  void _pollAuth() {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isLoading) {
      _authReady = true;
      _maybeNavigate();
    } else {
      Future.delayed(const Duration(milliseconds: 100), _pollAuth);
    }
  }

  Future<void> _maybeNavigate() async {
    if (!_authReady || !_minTimeDone || _navigating || !mounted) return;
    _navigating = true;
    await _exitCtrl.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secAnim) => const MainTabs(),
        transitionsBuilder: (ctx, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (ctx, child) => Opacity(opacity: 1.0 - _exitCtrl.value, child: child),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F2ED),
        body: Stack(
          // ★ 关键：StackFit.expand 让所有子组件撑满全屏
          fit: StackFit.expand,
          children: [
            // 底部装饰光晕
            Positioned(
              bottom: -80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF07C160).withValues(alpha: 0.12),
                        const Color(0xFF07C160).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 主内容 — 垂直居中
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App 名称 + 标语
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          const Text(
                            '猴哥星球',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D1D1F),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '专业刷题 · 轻松备考',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // 底部 loading 点
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: FadeTransition(
                      opacity: _textFade,
                      child: const _PulsingDots(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i * 0.25;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, child) {
            final raw = (_ctrl.value - delay) % 1.0;
            final t = raw < 0.5 ? raw * 2 : (1.0 - raw) * 2;
            final scale = 0.55 + 0.45 * t;
            final opacity = 0.25 + 0.75 * t;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7 * scale,
              height: 7 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF07C160).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
