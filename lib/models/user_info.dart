/// 用户信息模型（参考 Android 版 UserInfo.kt）
class UserInfo {
  final int id;
  final String? nickname;
  final String? avatarUrl;
  final int? gender;
  final String? phone;
  final bool? hasPassword;
  final bool? hasPhone;
  final String? username;

  UserInfo({
    required this.id,
    this.nickname,
    this.avatarUrl,
    this.gender,
    this.phone,
    this.hasPassword,
    this.hasPhone,
    this.username,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int? ?? 0,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] as int?,
      phone: json['phone'] as String?,
      hasPassword: json['hasPassword'] as bool?,
      hasPhone: json['hasPhone'] as bool?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'phone': phone,
      'hasPassword': hasPassword,
      'hasPhone': hasPhone,
      'username': username,
    };
  }
}
