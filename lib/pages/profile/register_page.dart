import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/legal_urls.dart';
import '../../providers/auth_provider.dart';

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
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 96, 32, 28),
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
                          decoration: const BoxDecoration(color: Color(0xFFBDEFD2), shape: BoxShape.circle),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(color: Color(0xFF07C160), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 标题
                const Text(
                  '您好，一键注册',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Color(0xFF171717)),
                ),
                const SizedBox(height: 34),

                // 手机号
                _buildRoundedInput(
                  controller: _phoneController,
                  hint: '手机号',
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                ),
                const SizedBox(height: 14),

                // 验证码
                _buildCodeInput(),
                const SizedBox(height: 14),

                // 密码
                _buildPasswordInput(
                  controller: _passwordController,
                  hint: '设置6-20位密码',
                  visible: _passwordVisible,
                  onToggle: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
                const SizedBox(height: 14),

                // 确认密码
                _buildPasswordInput(
                  controller: _confirmPasswordController,
                  hint: '再次输入密码',
                  visible: _confirmPasswordVisible,
                  onToggle: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                ),
                const SizedBox(height: 34),

                // 注册按钮
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _register(authProvider),
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
                            : const Text('立即注册'),
                      ),
                    );
                  },
                ),

                // 错误提示
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final err = authProvider.registerError ?? authProvider.codeError;
                    if (err != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Center(child: Text(err, style: const TextStyle(color: AppColors.wrongRed, fontSize: 13))),
                      );
                    }
                    return const SizedBox(height: 10);
                  },
                ),

                // 返回登录
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('返回登录', style: TextStyle(fontSize: 13)),
                  ),
                ),

                // 用户协议
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 10, color: Color(0xFFC2C2C2)),
                      children: [
                        const TextSpan(text: '注册即表示你已阅读并同意'),
                        TextSpan(
                          text: '用户协议',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openUrl(LegalUrls.userAgreement),
                        ),
                        const TextSpan(text: '与'),
                        TextSpan(
                          text: '隐私政策',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openUrl(LegalUrls.privacyPolicy),
                        ),
                      ],
                    ),
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

  Widget _buildRoundedInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
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
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          counterText: '',
        ),
        style: const TextStyle(color: Color(0xFF222222), fontSize: 14),
      ),
    );
  }

  Widget _buildCodeInput() {
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
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: '验证码',
                hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                counterText: '',
              ),
              style: const TextStyle(color: Color(0xFF222222), fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: _countdown > 0 ? null : _sendCode,
            child: Container(
              width: 108,
              alignment: Alignment.center,
              child: Text(
                _countdown > 0 ? '${_countdown}s' : '获取验证码',
                style: TextStyle(
                  fontSize: 13,
                  color: _countdown > 0 ? const Color(0xFFAAAAAA) : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
  }) {
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
              controller: controller,
              obscureText: !visible,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                counterText: '',
              ),
              style: const TextStyle(color: Color(0xFF222222), fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(
              visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFFAAAAAA),
              size: 20,
            ),
            onPressed: onToggle,
            padding: const EdgeInsets.only(right: 8),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的手机号')));
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendCode(phone);
    if (success) {
      _startCountdown();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('验证码已发送')));
    }
  }

  void _startCountdown() {
    _countdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) _countdownTimer?.cancel();
        });
      }
    });
  }

  Future<void> _register(AuthProvider authProvider) async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (phone.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的手机号')));
      return;
    }
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入验证码')));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码至少6位')));
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次密码输入不一致')));
      return;
    }

    setState(() => _isLoading = true);
    authProvider.clearRegisterError();

    final success = await authProvider.register(phone: phone, code: code, password: password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('注册成功')));
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接，请检查网络')),
        );
      }
    }
  }
}
