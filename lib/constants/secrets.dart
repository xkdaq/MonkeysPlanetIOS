/// 敏感配置 - 不提交到 Git
/// 复制 secrets.example.dart 并填入真实值
class Secrets {
  const Secrets._();

  /// AES 加密密钥（16位）
  static const String aesKey = '47ccmuRaEWyYFmVn';

  /// AES 初始化向量（16位）
  static const String aesIv = 'K5i9TbRSthzyaQ5H';

  /// 接口签名密钥
  static const String signKey = r'XukeExam2026@#$';
}
