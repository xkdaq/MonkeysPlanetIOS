import 'package:flutter/foundation.dart';
import '../models/user_info.dart';
import '../services/auth_storage.dart';
import '../services/user_service.dart';

/// 认证状态管理（参考 Android 版 ProfileViewModel + LoginViewModel + RegisterViewModel）
class AuthProvider with ChangeNotifier {
  final AuthStorage _authStorage;
  late final UserService _userService;

  UserInfo? _userInfo;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  // 登录相关
  bool _loginLoading = false;
  String? _loginError;

  // 注册相关
  bool _registerLoading = false;
  String? _registerError;
  bool _codeSending = false;
  String? _codeError;

  AuthProvider(this._authStorage) {
    _userService = UserService(_authStorage);
    _init();
  }

  // Getters
  UserInfo? get userInfo => _userInfo;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get loginLoading => _loginLoading;
  String? get loginError => _loginError;
  bool get registerLoading => _registerLoading;
  String? get registerError => _registerError;
  bool get codeSending => _codeSending;
  String? get codeError => _codeError;
  String get displayName => _userInfo?.nickname ?? '猴哥星球用户';
  String get displayId => _userInfo != null ? 'ID: 用户_${_userInfo!.id}' : '';

  /// 初始化：检查登录状态
  Future<void> _init() async {
    _isLoading = true;
    try {
      _isLoggedIn = await _authStorage.isLoggedIn();
      if (_isLoggedIn) {
        _userInfo = await _authStorage.getUserInfo();
        // 尝试从服务器获取最新用户信息
        try {
          final result = await _userService.getUserInfo();
          if (result.isSuccess && result.data != null) {
            _userInfo = result.data;
            await _authStorage.saveUserInfo(result.data!);
          }
        } catch (_) {}
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// 登录
  Future<bool> login(String phone, String password) async {
    _loginLoading = true;
    _loginError = null;
    notifyListeners();

    try {
      final result = await _userService.login(phone, password);
      if (result.isSuccess && result.data != null) {
        // 保存 token 和用户信息
        await _authStorage.saveToken(result.data!.token);
        if (result.data!.userInfo != null) {
          _userInfo = result.data!.userInfo;
          await _authStorage.saveUserInfo(result.data!.userInfo!);
        }
        _isLoggedIn = true;
        _loginLoading = false;
        notifyListeners();
        return true;
      } else {
        _loginError = result.msg ?? '登录失败，请重试';
        _loginLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loginError = '网络异常，请检查网络连接';
      _loginLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 发送验证码
  Future<bool> sendCode(String phone) async {
    // 验证手机号格式
    if (phone.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _codeError = '请输入正确的手机号';
      notifyListeners();
      return false;
    }

    _codeSending = true;
    _codeError = null;
    notifyListeners();

    try {
      final result = await _userService.sendVerifyCode(phone);
      if (result.isSuccess) {
        _codeSending = false;
        notifyListeners();
        return true;
      } else {
        _codeError = result.msg ?? '验证码发送失败';
        _codeSending = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _codeError = '网络异常，请检查网络连接';
      _codeSending = false;
      notifyListeners();
      return false;
    }
  }

  /// 注册
  Future<bool> register({
    required String phone,
    required String code,
    required String password,
  }) async {
    // 验证
    if (phone.length != 11 || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _registerError = '请输入正确的手机号';
      notifyListeners();
      return false;
    }
    if (code.isEmpty) {
      _registerError = '请输入验证码';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _registerError = '密码至少6位';
      notifyListeners();
      return false;
    }

    _registerLoading = true;
    _registerError = null;
    notifyListeners();

    try {
      final result = await _userService.register(
        phone: phone,
        code: code,
        password: password,
      );
      if (result.isSuccess && result.data != null) {
        await _authStorage.saveToken(result.data!.token);
        if (result.data!.userInfo != null) {
          _userInfo = result.data!.userInfo;
          await _authStorage.saveUserInfo(result.data!.userInfo!);
        }
        _isLoggedIn = true;
        _registerLoading = false;
        notifyListeners();
        return true;
      } else {
        _registerError = result.msg ?? '注册失败';
        _registerLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _registerError = '网络异常，请检查网络连接';
      _registerLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    await _authStorage.clearLoginState();
    _userInfo = null;
    _isLoggedIn = false;
    _loginError = null;
    _registerError = null;
    notifyListeners();
  }

  /// 刷新用户信息
  Future<void> refreshUserInfo() async {
    try {
      final result = await _userService.getUserInfo();
      if (result.isSuccess && result.data != null) {
        _userInfo = result.data;
        await _authStorage.saveUserInfo(result.data!);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 更新昵称（成功后刷新 userInfo）
  Future<void> updateNickname(String nickname) async {
    final result = await _userService.updateNickname(nickname);
    if (!result.isSuccess) throw Exception(result.msg ?? '昵称更新失败');
    await refreshUserInfo();
  }

  /// 更新性别（成功后刷新 userInfo）
  Future<void> updateGender(int gender) async {
    final result = await _userService.updateGender(gender);
    if (!result.isSuccess) throw Exception(result.msg ?? '性别更新失败');
    await refreshUserInfo();
  }

  /// 上传头像文件（成功后刷新 userInfo）
  Future<void> uploadAvatar(String filePath) async {
    final result = await _userService.uploadAvatar(filePath);
    if (!result.isSuccess) throw Exception(result.msg ?? '头像上传失败');
    await refreshUserInfo();
  }

  /// 清除错误信息
  void clearLoginError() {
    _loginError = null;
    notifyListeners();
  }

  void clearRegisterError() {
    _registerError = null;
    notifyListeners();
  }

  void clearCodeError() {
    _codeError = null;
    notifyListeners();
  }
}
