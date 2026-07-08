import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'auth_storage.dart';
import 'http_client.dart';

/// iOS 设备信息获取与注册服务。
/// 启动时调用 [register] 上报设备信息到后端。
class DeviceInfoService {
  final AuthStorage _authStorage;

  DeviceInfoService(this._authStorage);

  /// 获取并注册设备信息。
  /// 如果已注册过且 deviceId 相同，则跳过。
  /// 失败时静默处理，不影响 App 正常使用。
  Future<void> register() async {
    try {
      final existingDeviceId = await _authStorage.getDeviceId();
      final deviceInfo = await _getDeviceInfo();

      // 如果已注册且 deviceId 没变，直接返回
      if (existingDeviceId != null &&
          existingDeviceId.isNotEmpty &&
          existingDeviceId == deviceInfo['deviceId']) {
        return;
      }

      // 调用后端注册接口（不携带 Token，因为此时可能未登录）
      // 注意：HttpClient 已配置 baseUrl，这里用相对路径即可，
      // 否则绝对路径会影响签名拦截器的 sign 计算。
      final dio = HttpClient(_authStorage).dio;
      final response = await dio.post('mp/device/register', data: deviceInfo);

      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['code'] == 0) {
        // 注册成功，保存本地 deviceId
        await _authStorage.saveDeviceId(deviceInfo['deviceId'] as String);
      }
    } catch (e) {
      // 静默失败：不影响 App 启动流程
      if (kDebugMode) print('[DeviceInfo] 注册失败: $e');
    }
  }

  /// 获取设备信息 Map
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;

    // 设备标识：iOS 使用 identifierForVendor（UUID）
    final deviceId =
        iosInfo.identifierForVendor ??
        'ios_${DateTime.now().millisecondsSinceEpoch}';

    // 从 PackageInfo 获取真实版本号
    final packageInfo = await PackageInfo.fromPlatform();

    return {
      'deviceId': deviceId,
      'platform': 'ios',
      'deviceName': iosInfo.name,
      'deviceModel': iosInfo.model,
      'osVersion': 'iOS ${iosInfo.systemVersion}',
      'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
    };
  }
}
