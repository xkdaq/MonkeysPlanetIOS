import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../constants/api_config.dart';

/// AES 加解密服务（参考 Android 版 ExamDecryptInterceptor.kt 和 AesCipher.kt）
class CryptoService {
  /// AES/CBC/PKCS5 解密
  static String decryptAES(String encryptedBase64) {
    final key = Uint8List.fromList(utf8.encode(ApiConfig.aesKey));
    final iv = Uint8List.fromList(utf8.encode(ApiConfig.aesIv));
    final encryptedBytes = base64Decode(encryptedBase64);

    final cipher = CBCBlockCipher(AESEngine())
      ..init(
        false,
        ParametersWithIV(KeyParameter(key), iv),
      );

    final output = Uint8List(encryptedBytes.length);

    var offset = 0;
    while (offset < encryptedBytes.length) {
      final chunkSize = cipher.processBlock(
        encryptedBytes,
        offset,
        output,
        offset,
      );
      offset += chunkSize;
    }

    // PKCS5/7 去除填充
    final padLen = output[encryptedBytes.length - 1];
    final dataLen = encryptedBytes.length - padLen;
    return utf8.decode(output.sublist(0, dataLen));
  }
}
