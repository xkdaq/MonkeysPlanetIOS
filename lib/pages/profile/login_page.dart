import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_rebuild);
    _passwordController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _phoneController.removeListener(_rebuild);
    _passwordController.removeListener(_rebuild);
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 右上角光晕装饰
          Positioned(
            top: -76,
            right: -60,
            child: Container(
              width: 230,
              height: 230,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 主内容
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 96, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // 双圆形装饰
                  SizedBox(
                    width: 74,
                    height: 48,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFBDEFD2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF07C160),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 标题
                  const Text(
                    '您好，欢迎登录！',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Color(0xFF171717)),
                  ),
                  const SizedBox(height: 44),

                  // 手机号输入
                  _buildInput(
                    controller: _phoneController,
                    hint: '手机号',
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                  ),
                  const SizedBox(height: 16),

                  // 密码输入
                  _buildPasswordInput(),
                  const SizedBox(height: 46),

                  // 登录按钮
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final canLogin = _phoneController.text.isNotEmpty && _passwordController.text.isNotEmpty && !_isLoading;
                      return SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: canLogin ? () => _login(authProvider) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: const Color(0xFFB2DFC5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('登录'),
                        ),
                      );
                    },
                  ),

                  // 错误提示
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      if (authProvider.loginError != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Center(
                            child: Text(authProvider.loginError!, style: const TextStyle(color: AppColors.wrongRed, fontSize: 13)),
                          ),
                        );
                      }
                      return const SizedBox(height: 12);
                    },
                  ),

                  // 去注册
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('去注册', style: TextStyle(fontSize: 13)),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 底部标语
                  const Center(
                    child: Text(
                      'I THINK I CAN AND I WILL',
                      style: TextStyle(fontSize: 9, color: Color(0xFFD7D7D7), letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
          ),
          // 返回按钮（在 ScrollView 之上，确保可接收触摸）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF171717)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          counterText: '',
          suffixIcon: suffix,
        ),
        style: const TextStyle(color: Color(0xFF222222), fontSize: 14),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return Container(
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: const InputDecoration(
                hintText: '密码',
                hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              style: const TextStyle(color: Color(0xFF222222), fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFFAAAAAA),
              size: 20,
            ),
            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            padding: const EdgeInsets.only(right: 8),
          ),
        ],
      ),
    );
  }

  Future<void> _login(AuthProvider authProvider) async {
    setState(() => _isLoading = true);
    authProvider.clearLoginError();

    final success = await authProvider.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登录成功'), duration: Duration(seconds: 2)),
        );
      }
    }
  }
}
