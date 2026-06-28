import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// 注册页（参考 Android 版 RegisterActivity）
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: const Text('注册', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              '创建账号',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '注册后即可刷题学习',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // 手机号
            const Text('手机号',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: const InputDecoration(
                hintText: '请输入手机号',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),

            // 验证码
            const Text('验证码',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: '请输入验证码',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_countdown > 0)
                        ? null
                        : () => _sendCode(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: Text(
                      _countdown > 0 ? '${_countdown}s' : '获取验证码',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 密码
            const Text('密码',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                hintText: '请输入密码（至少6位）',
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textHint,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 确认密码
            const Text('确认密码',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              decoration: InputDecoration(
                hintText: '请再次输入密码',
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.textHint,
                  ),
                  onPressed: () => setState(
                      () => _confirmPasswordVisible = !_confirmPasswordVisible),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 用户协议
            _buildLegalAgreement(),
            const SizedBox(height: 24),

            // 注册按钮
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _register(context, authProvider),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('立即注册'),
                );
              },
            ),

            // 错误提示
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.registerError != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      authProvider.registerError!,
                      style: const TextStyle(
                        color: AppColors.wrongRed,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (authProvider.codeError != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      authProvider.codeError!,
                      style: const TextStyle(
                        color: AppColors.wrongRed,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),

            const SizedBox(height: 16),

            // 已有账号，去登录
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '已有账号？',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '去登录',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalAgreement() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.textHint),
        children: [
          const TextSpan(text: '注册即表示你已阅读并同意'),
          TextSpan(
            text: '用户协议',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            recognizer: null, // 简化处理，实际应使用 TapGestureRecognizer
          ),
          const TextSpan(text: '与'),
          TextSpan(
            text: '隐私政策',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            recognizer: null,
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final phone = _phoneController.text.trim();

    if (phone.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }

    final success = await authProvider.sendCode(phone);
    if (success) {
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送')),
        );
      }
    }
  }

  void _startCountdown() {
    _countdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) {
            _countdownTimer?.cancel();
          }
        });
      }
    });
  }

  Future<void> _register(
      BuildContext context, AuthProvider authProvider) async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 前端验证
    if (phone.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入验证码')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码至少6位')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次密码输入不一致')),
      );
      return;
    }

    setState(() => _isLoading = true);
    authProvider.clearRegisterError();

    final success = await authProvider.register(
      phone: phone,
      code: code,
      password: password,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // 注册成功，返回上一页
        Navigator.pop(context);
        Navigator.pop(context); // 如果是从登录页来的
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功')),
        );
      }
    }
  }
}
