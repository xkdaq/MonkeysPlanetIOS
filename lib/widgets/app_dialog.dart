import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum AppDialogActionStyle { normal, destructive, cancel }

class AppDialogAction {
  final String text;
  final AppDialogActionStyle style;
  final VoidCallback onPressed;
  final bool isDefault;

  const AppDialogAction({
    required this.text,
    this.style = AppDialogActionStyle.normal,
    required this.onPressed,
    this.isDefault = false,
  });
}

/// iOS 风格弹框，固定宽度 270，白底圆角 14px
class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<AppDialogAction> actions;

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    required List<AppDialogAction> actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black54,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题 + 内容区
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6C6C70),
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (content != null) ...[
                    const SizedBox(height: 12),
                    content!,
                  ],
                ],
              ),
            ),

            // 分割线
            Container(height: 0.5, color: const Color(0xFFD1D1D6)),

            // 按钮区
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (actions.length == 2) {
      // 两个按钮横排
      return SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(child: _buildActionButton(actions[0])),
            Container(width: 0.5, height: 52, color: const Color(0xFFD1D1D6)),
            Expanded(child: _buildActionButton(actions[1])),
          ],
        ),
      );
    }
    // 一个或多个按钮竖排
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: actions.asMap().entries.map((e) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (e.key > 0)
              Container(height: 0.5, color: const Color(0xFFD1D1D6)),
            SizedBox(height: 52, child: _buildActionButton(e.value)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(AppDialogAction action) {
    Color color;
    FontWeight weight;
    switch (action.style) {
      case AppDialogActionStyle.destructive:
        color = const Color(0xFFFF3B30);
        weight = FontWeight.w400;
        break;
      case AppDialogActionStyle.cancel:
        color = const Color(0xFF8E8E93);
        weight = FontWeight.w400;
        break;
      case AppDialogActionStyle.normal:
        color = AppColors.primary;
        weight = action.isDefault ? FontWeight.w600 : FontWeight.w400;
        break;
    }

    return TextButton(
      onPressed: action.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        minimumSize: const Size(double.infinity, 52),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        action.text,
        style: TextStyle(fontSize: 16, color: color, fontWeight: weight),
      ),
    );
  }
}
