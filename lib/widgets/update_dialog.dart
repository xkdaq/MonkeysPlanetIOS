import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../services/version_check_service.dart';
import 'app_dialog.dart';

/// 版本更新弹框。
///
/// - 强制更新：只显示「立即更新」按钮，不可关闭，必须更新后才能使用 App。
/// - 可选更新：显示「暂不更新」+「立即更新」两个按钮，用户可选择忽略。
class UpdateDialog {
  /// 显示版本更新弹框，返回 true 表示用户点击了「立即更新」。
  static Future<bool?> show({
    required BuildContext context,
    required VersionUpdateInfo info,
  }) {
    final actions = <AppDialogAction>[];

    if (info.isForced) {
      // 强制更新：只有一个按钮
      actions.add(AppDialogAction(
        text: '立即更新',
        style: AppDialogActionStyle.normal,
        isDefault: true,
        onPressed: () {
          Navigator.of(context).pop(true);
        },
      ));
    } else {
      // 可选更新：两个按钮
      actions.add(AppDialogAction(
        text: '暂不更新',
        style: AppDialogActionStyle.cancel,
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ));
      actions.add(AppDialogAction(
        text: '立即更新',
        style: AppDialogActionStyle.normal,
        isDefault: true,
        onPressed: () {
          Navigator.of(context).pop(true);
        },
      ));
    }

    return AppDialog.show<bool>(
      context: context,
      title: info.title.isNotEmpty ? info.title : '发现新版本 ${info.versionName}',
      message: info.content.isNotEmpty ? info.content : null,
      actions: actions,
      barrierDismissible: !info.isForced, // 强制更新不可点外部关闭
    );
  }

  /// 打开下载链接（App Store 或外部浏览器）
  /// 
  /// 注意：App Store 链接在 iOS 模拟器上无法打开（没有 App Store 应用），
  /// 在真机上会正常跳转到 App Store。无法打开时降级为在 Safari 中浏览网页版。
  static Future<bool> openDownloadUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    try {
      // 先尝试用外部应用打开（真机上会唤起 App Store）
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // 外部应用不可用（如模拟器），降级为在 Safari 中打开网页
      if (kDebugMode) {
        print('[UpdateDialog] 外部应用无法打开，降级为 Safari 内打开');
      }
      return await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
