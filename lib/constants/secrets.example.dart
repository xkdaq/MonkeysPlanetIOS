/// 敏感配置模板 - 复制为 secrets.dart 并填入真实值
///
/// 使用方式:
///   cp lib/constants/secrets.example.dart lib/constants/secrets.dart
///   然后编辑 secrets.dart 填入真实的 AES_KEY / AES_IV / SIGN_KEY
///   secrets.dart 已被 .gitignore 忽略，不会提交
class Secrets {
  const Secrets._();

  /// AES 加密密钥（16位字符串）
  static const String aesKey = 'YOUR_16_CHAR_AES_KEY';

  /// AES 初始化向量（16位字符串）
  static const String aesIv = 'YOUR_16_CHAR_AES_IV';

  /// 接口签名密钥
  static const String signKey = 'YOUR_SIGN_KEY';
}
