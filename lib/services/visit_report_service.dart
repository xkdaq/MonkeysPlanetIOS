import 'auth_storage.dart';
import 'http_client.dart';

/// 访问上报服务
/// 在关键页面和事件触发时，上报访问日志到 /api/visit/report
class VisitReportService {
  static VisitReportService? _instance;

  late final HttpClient _client;

  VisitReportService._(AuthStorage authStorage) {
    _client = HttpClient(authStorage);
  }

  factory VisitReportService(AuthStorage authStorage) {
    _instance ??= VisitReportService._(authStorage);
    return _instance!;
  }

  /// 上报通用页面访问
  ///
  /// [eventType] 事件类型：
  ///   - 'page_view'：通用页面访问
  ///   - 'detail_view'：资料详情
  ///   - 'note_detail_view'：笔记详情
  ///   - 'exam_page_view'：题库/刷题页面
  ///   - 'exam_practice_start'：开始练习
  ///   - 'exam_practice_complete'：完成练习
  /// [pagePath] 页面路径（可选）
  /// [materialId] 资料/笔记 ID（可选）
  /// [materialTitle] 资料/笔记标题（可选）
  Future<void> report({
    required String eventType,
    String? pagePath,
    int? materialId,
    String? materialTitle,
  }) async {
    try {
      final data = <String, dynamic>{
        'eventType': eventType,
      };
      if (pagePath != null && pagePath.isNotEmpty) {
        data['pagePath'] = pagePath;
      }
      if (materialId != null) {
        data['materialId'] = materialId;
      }
      if (materialTitle != null && materialTitle.isNotEmpty) {
        data['materialTitle'] = materialTitle;
      }
      await _client.post('api/visit/report', data: data);
    } catch (e) {
      // 上报失败不阻塞业务，静默忽略
    }
  }

  /// 快捷方法：题库页面访问
  Future<void> reportExamPageView({String? pagePath}) async {
    await report(eventType: 'exam_page_view', pagePath: pagePath);
  }

  /// 快捷方法：开始练习
  Future<void> reportPracticeStart({String? pagePath, int? bankId}) async {
    await report(
      eventType: 'exam_practice_start',
      pagePath: pagePath ?? (bankId != null ? 'practice/$bankId' : null),
    );
  }

  /// 快捷方法：完成练习
  Future<void> reportPracticeComplete({String? pagePath, int? bankId}) async {
    await report(
      eventType: 'exam_practice_complete',
      pagePath: pagePath ?? (bankId != null ? 'practice/$bankId' : null),
    );
  }
}
