// ignore: uri_does_not_exist
import 'secrets.dart';

/// API 配置常量。
/// Base URL（公开）和 AES_KEY/AES_IV/SIGN_KEY（从 secrets.dart 读取）。

class ApiConfig {
  const ApiConfig._();

  /// API 基础地址
  static const String baseUrl = 'https://api.monkeysxu.top/';

  /// AES 加密密钥（16位字符串）
  static const String aesKey = Secrets.aesKey;

  /// AES 初始化向量（16位字符串）
  static const String aesIv = Secrets.aesIv;

  /// 接口签名密钥
  static const String signKey = Secrets.signKey;
}
