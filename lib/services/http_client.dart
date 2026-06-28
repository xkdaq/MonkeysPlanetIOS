import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../constants/api_config.dart';
import 'auth_storage.dart';
import 'crypto_service.dart';

/// HTTP 客户端（参考 Android 版 RetrofitClient + SignInterceptor + TokenInterceptor + ExamDecryptInterceptor）
class HttpClient {
  late final Dio _dio;
  final AuthStorage _authStorage;

  HttpClient(this._authStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 添加拦截器：签名 → Token → 解密
    _dio.interceptors.add(_SignInterceptor());
    _dio.interceptors.add(_TokenInterceptor(_authStorage));
    _dio.interceptors.add(_ExamDecryptInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[HTTP] $obj'),
    ));
  }

  Dio get dio => _dio;

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
  }) async {
    return await _dio.post(path, data: data);
  }

  /// PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    return await _dio.put(path, data: data);
  }

  /// 上传文件
  Future<Response> uploadFile(
    String path, {
    required String filePath,
    required String fileField,
    String? fileName,
  }) async {
    final formData = FormData.fromMap({
      fileField: await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return await _dio.post(path, data: formData);
  }
}

/// 签名拦截器（参考 Android 版 SignInterceptor.kt）
class _SignInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final path = options.path;

    // MD5(SIGN_KEY + timestamp + path)
    final sign = _md5('${ApiConfig.signKey}$timestamp$path');

    options.headers['X-Timestamp'] = timestamp;
    options.headers['X-Sign'] = sign;

    handler.next(options);
  }

  String _md5(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString().padLeft(32, '0');
  }
}

/// Token 拦截器（参考 Android 版 TokenInterceptor.kt）
class _TokenInterceptor extends Interceptor {
  final AuthStorage _authStorage;

  _TokenInterceptor(this._authStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _authStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    handler.next(options);
  }
}

/// 考试模块加密响应解密拦截器（参考 Android 版 ExamDecryptInterceptor.kt）
class _ExamDecryptInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final encrypted = data['encrypted'] as bool? ?? false;
        if (encrypted) {
          final encryptedData = data['data'] as String? ?? '';
          if (encryptedData.isNotEmpty) {
            final decryptedStr = CryptoService.decryptAES(encryptedData);
            final decryptedJson = jsonDecode(decryptedStr);

            // 重建响应
            final result = <String, dynamic>{
              'code': data['code'] ?? 0,
              'msg': data['msg'] ?? '',
              'data': decryptedJson,
            };
            response.data = result;
          }
        }
      }
    } catch (e) {
      print('[Decrypt] 解密失败: $e');
    }
    handler.next(response);
  }
}
