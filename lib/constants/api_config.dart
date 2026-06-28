/// API 配置常量
/// 
/// 真实值通过 --dart-define-from-file=secrets.json 注入（编译时常量），
/// 不传该参数则回退到此处占位值，可正常编译但 API 调用会失败。
///
/// 使用方式：
///   1. cp secrets.example.json secrets.json
///   2. 在 secrets.json 中填入真实值（已 .gitignore）
///   3. flutter run --dart-define-from-file=secrets.json
///
/// 对应 Android 项目的 secrets.properties
class ApiConfig {
  const ApiConfig._();

  /// API 基础地址
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://your-api-domain.com/',
  );

  /// AES 加密密钥（16位字符串）
  static const String aesKey = String.fromEnvironment(
    'AES_KEY',
    defaultValue: 'YOUR_16_CHAR_AES_KEY',
  );

  /// AES 初始化向量（16位字符串）
  static const String aesIv = String.fromEnvironment(
    'AES_IV',
    defaultValue: 'YOUR_16_CHAR_AES_IV',
  );

  /// 接口签名密钥
  static const String signKey = String.fromEnvironment(
    'SIGN_KEY',
    defaultValue: 'YOUR_SIGN_KEY',
  );
}
