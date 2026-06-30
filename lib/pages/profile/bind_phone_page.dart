import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class BindPhonePage extends StatefulWidget {
  const BindPhonePage({super.key});

  @override
  State<BindPhonePage> createState() => _BindPhonePageState();
}

class _BindPhonePageState extends State<BindPhonePage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  int _countdown = 0;
  Timer? _countdownTimer;
  bool _binding = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final phone = auth.userInfo?.phone;
        final isBound = phone != null && phone.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('绑定手机号', style: TextStyle(fontWeight: FontWeight.w600)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(color: AppColors.bgDivider, height: 0.5),
            ),
          ),
          body: isBound ? _buildBoundView(context, phone) : _buildBindForm(context),
        );
      },
    );
  }

  // ──── 已绑定视图 ────

  Widget _buildBoundView(BuildContext context, String phone) {
    final masked = phone.length >= 11
        ? '${phone.substring(0, 3)} **** ${phone.substring(7)}'
        : phone;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      children: [
        // 绑定状态卡片
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F7EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.primary, size: 13),
                        SizedBox(width: 4),
                        Text('已绑定', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                masked,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              const Text(
                '该手机号已与账号绑定',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 更换按钮
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('换绑功能即将上线'), duration: Duration(seconds: 2)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.bgDivider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('更换手机号', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  // ──── 未绑定 - 绑定表单 ────

  Widget _buildBindForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        // 说明文字
        const Text(
          '绑定手机号后可使用手机号登录，也可用于找回密码',
          style: TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.6),
        ),
        const SizedBox(height: 24),

        // 表单卡片
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              // 手机号
              _buildInputRow(
                label: '手机号',
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '请输入手机号',
                    hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
                    border: InputBorder.none,
                    isCollapsed: true,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              Container(height: 0.5, color: AppColors.bgDivider, margin: const EdgeInsets.only(left: 16)),
              // 验证码
              _buildCodeRow(),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 绑定按钮
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _binding ? null : _bindPhone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFFB2DFC5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _binding
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('立即绑定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildCodeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(
            width: 52,
            child: Text('验证码', style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '请输入验证码',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
                border: InputBorder.none,
                isCollapsed: true,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _countdown > 0 ? null : _sendCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _countdown > 0 ? const Color(0xFFF0F0F0) : const Color(0xFFE8F7EF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _countdown > 0 ? '${_countdown}s' : '获取验证码',
                style: TextStyle(
                  fontSize: 13,
                  color: _countdown > 0 ? AppColors.textHint : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendCode() {
    final phone = _phoneController.text.trim();
    if (phone.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的手机号')));
      return;
    }
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('验证码已发送'), duration: Duration(seconds: 2)));
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) timer.cancel();
        });
      }
    });
  }

  Future<void> _bindPhone() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (phone.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的手机号')));
      return;
    }
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入6位验证码')));
      return;
    }
    setState(() => _binding = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _binding = false);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('绑定成功'), duration: Duration(seconds: 2)));
  }
}
