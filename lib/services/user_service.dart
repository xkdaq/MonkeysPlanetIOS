import '../models/api_response.dart';
import '../models/user_info.dart';
import 'auth_storage.dart';
import 'http_client.dart';

/// 用户 API 服务（参考 Android 版 UserApiService.kt + LoginRepository.kt）
class UserService {
  late final HttpClient _client;

  UserService(AuthStorage authStorage) {
    _client = HttpClient(authStorage);
  }

  /// 手机号密码登录
  Future<ApiResponse<AuthResult>> login(String phone, String password) async {
    final response = await _client.post(
      'mp/auth/login/phone',
      data: {'phone': phone, 'password': password},
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AuthResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 发送验证码
  Future<ApiResponse<dynamic>> sendVerifyCode(String phone) async {
    final response = await _client.get(
      'mp/sms/send',
      queryParameters: {'phone': phone},
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  /// 注册
  Future<ApiResponse<AuthResult>> register({
    required String phone,
    required String code,
    required String password,
  }) async {
    final response = await _client.post(
      'mp/auth/register',
      data: {
        'phone': phone,
        'code': code,
        'password': password,
      },
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AuthResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 获取用户信息
  Future<ApiResponse<UserInfo>> getUserInfo() async {
    final response = await _client.get('mp/user/info');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => UserInfo.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 更新昵称
  Future<ApiResponse<dynamic>> updateNickname(String nickname) async {
    final response = await _client.put(
      'mp/user/nickname',
      data: {'nickname': nickname},
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  /// 更新性别
  Future<ApiResponse<dynamic>> updateGender(int gender) async {
    final response = await _client.put(
      'mp/user/gender',
      data: {'gender': gender},
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  /// 更新头像 URL
  Future<ApiResponse<dynamic>> updateAvatar(String avatarUrl) async {
    final response = await _client.put(
      'mp/user/avatar',
      data: {'avatarUrl': avatarUrl},
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  /// 上传头像文件
  Future<ApiResponse<AvatarUploadResult>> uploadAvatar(String filePath) async {
    final response = await _client.uploadFile(
      'mp/user/avatar/upload',
      filePath: filePath,
      fileField: 'file',
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AvatarUploadResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 修改密码
  Future<ApiResponse<dynamic>> changePassword({
    required String phone,
    String? oldPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      'mp/auth/password',
      data: {
        'phone': phone,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  /// 绑定手机号
  Future<ApiResponse<dynamic>> bindPhone({
    required String phone,
    required String code,
    required String password,
  }) async {
    final response = await _client.post(
      'mp/phone/bind',
      data: {
        'phone': phone,
        'code': code,
        'password': password,
      },
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }
}

/// 登录认证结果（参考 Android 版 AuthResult）
class AuthResult {
  final String token;
  final int? expire;
  final UserInfo? userInfo;

  AuthResult({
    required this.token,
    this.expire,
    this.userInfo,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String? ?? '',
      expire: json['expire'] as int?,
      userInfo: json['userInfo'] != null
          ? UserInfo.fromJson(json['userInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 头像上传结果（参考 Android 版 AvatarUploadData）
class AvatarUploadResult {
  final String? url;

  AvatarUploadResult({this.url});

  factory AvatarUploadResult.fromJson(Map<String, dynamic> json) {
    return AvatarUploadResult(
      url: json['url'] as String?,
    );
  }
}
