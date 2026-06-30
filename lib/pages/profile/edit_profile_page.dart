import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_dialog.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nicknameController;
  int _gender = -1;
  bool _saving = false;
  bool _uploadingAvatar = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final info = context.read<AuthProvider>().userInfo;
    _nicknameController = TextEditingController(text: info?.nickname ?? '');
    _gender = info?.gender ?? -1;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await _showPickSourceSheet();
    if (source == null) return;

    final XFile? file = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      // ignore: use_build_context_synchronously
      await context.read<AuthProvider>().uploadAvatar(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像更新成功'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), duration: const Duration(seconds: 2)),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<ImageSource?> _showPickSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFD1D1D6), borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('编辑资料', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('保存', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.bgDivider, height: 0.5),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              // 头像
              Center(
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgGray,
                          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
                        ),
                        child: ClipOval(
                          child: _uploadingAvatar
                              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                              : (auth.userInfo?.avatarUrl?.isNotEmpty == true
                                  ? Image.network(
                                      auth.userInfo!.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, e, s) => Image.asset('assets/images/default-avatar.png', fit: BoxFit.cover),
                                    )
                                  : Image.asset('assets/images/default-avatar.png', fit: BoxFit.cover)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '点击修改头像',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint.withValues(alpha: 0.8)),
                ),
              ),
              const SizedBox(height: 28),

              // 信息卡片
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    // 昵称
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 52,
                            child: Text('昵称', style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _nicknameController,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: '请输入昵称',
                                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 0.5, color: AppColors.bgDivider, margin: const EdgeInsets.only(left: 16)),

                    // 性别
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 52,
                            child: Text('性别', style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          ),
                          const Spacer(),
                          _genderChip('保密', -1),
                          const SizedBox(width: 8),
                          _genderChip('男', 1),
                          const SizedBox(width: 8),
                          _genderChip('女', 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 账号信息只读卡片
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    _readonlyRow('账号', auth.userInfo?.username ?? auth.userInfo?.id.toString() ?? '-'),
                    Container(height: 0.5, color: AppColors.bgDivider, margin: const EdgeInsets.only(left: 16)),
                    _readonlyRow('手机号', _maskPhone(auth.userInfo?.phone)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _genderChip(String label, int value) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _readonlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '未绑定';
    if (phone.length >= 11) return '${phone.substring(0, 3)}****${phone.substring(7)}';
    return phone;
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('昵称不能为空')));
      return;
    }

    setState(() => _saving = true);

    try {
      final auth = context.read<AuthProvider>();
      final oldNickname = auth.userInfo?.nickname ?? '';
      final oldGender = auth.userInfo?.gender ?? -1;

      if (nickname != oldNickname) {
        await auth.updateNickname(nickname);
      }
      if (_gender != oldGender) {
        if (!mounted) return;
        await context.read<AuthProvider>().updateGender(_gender == -1 ? 0 : _gender);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('保存成功'), duration: Duration(seconds: 2)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      await AppDialog.show(
        context: context,
        title: '保存失败',
        message: '网络异常，请检查后重试',
        actions: [
          AppDialogAction(
            text: '确定',
            isDefault: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }
  }
}
