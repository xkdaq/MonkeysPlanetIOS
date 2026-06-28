/// 通用 API 响应包装（参考 Android 版 ApiResponse.kt）
class ApiResponse<T> {
  final int code;
  final String? msg;
  final T? data;
  final bool? encrypted;
  final T? rows;
  final int? total;

  ApiResponse({
    required this.code,
    this.msg,
    this.data,
    this.encrypted,
    this.rows,
    this.total,
  });

  bool get isSuccess => code == 0;

  /// 兼容 data 和 rows 两个字段（后端分页用 rows）
  T? get listData => data ?? rows;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] as int? ?? -1,
      msg: json['msg'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      encrypted: json['encrypted'] as bool?,
      rows: json['rows'] != null && fromJsonT != null
          ? fromJsonT(json['rows'])
          : json['rows'] as T?,
      total: json['total'] as int?,
    );
  }
}
