import 'dart:async';
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

  /// 初始化：检查登录状态，并验证 token 有效性（防止 iOS Keychain 残留旧 token）
  Future<void> _init() async {
    _isLoading = true;
    try {
      _isLoggedIn = await _authStorage.isLoggedIn();
      if (_isLoggedIn) {
        _userInfo = await _authStorage.getUserInfo();
        // ★ 验证 token 有效性：如果 token 已过期或被清除，清理本地状态
        try {
          final result = await _userService.getUserInfo();
          if (result.isSuccess && result.data != null) {
            _userInfo = result.data;
            await _authStorage.saveUserInfo(result.data!);
          } else if (result.code == 401 || result.code == 500 ||
                     (result.msg?.contains('过期') == true) ||
                     (result.msg?.contains('未登录') == true)) {
            // token 失效，清理本地状态
            await _authStorage.clearLoginState();
            _isLoggedIn = false;
            _userInfo = null;
          }
        } catch (_) {
          // 网络异常时保持现有登录状态，不做清理
        }
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
      final deviceId = await _authStorage.getDeviceId();
      final result = await _userService.login(
        phone, password,
        clientType: 'ios',
        deviceId: deviceId,
      );
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
      final deviceId = await _authStorage.getDeviceId();
      final result = await _userService.register(
        phone: phone,
        code: code,
        password: password,
        clientType: 'ios',
        deviceId: deviceId,
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

  /// 上传头像文件（成功后立即更新本地头像并刷新 userInfo）
  Future<void> uploadAvatar(String filePath) async {
    final result = await _userService.uploadAvatar(filePath);
    if (!result.isSuccess) throw Exception(result.msg ?? '头像上传失败');

    // 上传成功，立即用返回的 URL 更新本地头像（不用等 refreshUserInfo 二次请求）
    final url = result.data?.url;
    if (url != null && url.isNotEmpty && _userInfo != null) {
      _userInfo = UserInfo(
        id: _userInfo!.id,
        username: _userInfo!.username,
        nickname: _userInfo!.nickname,
        avatarUrl: url,
        gender: _userInfo!.gender,
        phone: _userInfo!.phone,
        hasPassword: _userInfo!.hasPassword,
        hasPhone: _userInfo!.hasPhone,
      );
      await _authStorage.saveUserInfo(_userInfo!);
      notifyListeners();
    }

    // 再异步刷新完整用户信息兜底
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
