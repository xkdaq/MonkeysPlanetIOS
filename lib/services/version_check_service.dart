import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'http_client.dart';
import 'auth_storage.dart';

/// 版本更新信息
class VersionUpdateInfo {
  final int versionCode;
  final String versionName;
  final bool isForced; // true=强制更新，false=可选更新
  final String title;
  final String content;
  final String downloadUrl;

  VersionUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.isForced,
    required this.title,
    required this.content,
    required this.downloadUrl,
  });

  factory VersionUpdateInfo.fromJson(Map<String, dynamic> json) {
    return VersionUpdateInfo(
      versionCode: json['versionCode'] as int? ?? 0,
      versionName: json['versionName'] as String? ?? '',
      isForced: (json['updateType'] as String?) == 'forced',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
    );
  }
}

/// 版本更新检查服务。
/// App 启动时调用后端接口检查是否有新版本。
class VersionCheckService {
  final AuthStorage _authStorage;

  VersionCheckService(this._authStorage);

  /// 检查版本更新。
  /// 返回 [VersionUpdateInfo] 表示有新版本，null 表示已是最新或无更新配置。
  Future<VersionUpdateInfo?> check() async {
    try {
      // 获取当前 App 版本号
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;

      if (kDebugMode) {
        print('[VersionCheck] 当前版本: ${packageInfo.version}'
            ' (versionCode=$currentVersionCode)');
      }

      // 调用后端接口
      final dio = HttpClient(_authStorage).dio;
      final response = await dio.get(
        'api/version/check',
        queryParameters: {
          'platform': 'ios',
          'versionCode': currentVersionCode,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['code'] != 0) {
        if (kDebugMode) {
          print('[VersionCheck] 接口返回异常: ${data?['msg']}');
        }
        return null;
      }

      final result = data['data'] as Map<String, dynamic>?;
      if (result == null || result['hasUpdate'] != true) {
        if (kDebugMode) print('[VersionCheck] 已是最新版本');
        return null;
      }

      final info = VersionUpdateInfo.fromJson(result);
      if (kDebugMode) {
        print('[VersionCheck] 发现新版本: ${info.versionName}'
            ' (versionCode=${info.versionCode}, '
            '${info.isForced ? "强制" : "可选"}更新)');
      }
      return info;
    } catch (e) {
      // 检查更新失败不影响 App 正常使用
      if (kDebugMode) print('[VersionCheck] 检查失败: $e');
      return null;
    }
  }
}
