import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_info.dart';

/// Token 和用户信息的本地存储（参考 Android 版 TokenManager.kt）
class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _userInfoKey = 'user_info';

  final FlutterSecureStorage _secureStorage;

  AuthStorage() : _secureStorage = const FlutterSecureStorage();

  /// 保存 Token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// 获取 Token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// 保存用户信息
  Future<void> saveUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInfoKey, jsonEncode(userInfo.toJson()));
  }

  /// 获取用户信息
  Future<UserInfo?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userInfoKey);
    if (json != null && json.isNotEmpty) {
      try {
        return UserInfo.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// 清除登录状态
  Future<void> clearLoginState() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userInfoKey);
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
