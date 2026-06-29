import 'package:flutter/material.dart';

/// 轻量级 HTML 渲染组件，支持后台解析返回的 <p>/<span>/<strong>/<br> 及 color 内联样式
/// 无需额外依赖，直接输出 Flutter RichText
class HtmlContent extends StatelessWidget {
  final String html;
  final TextStyle baseStyle;
  final bool selectable;

  const HtmlContent({
    super.key,
    required this.html,
    required this.baseStyle,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(html);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final spans = _parseInline(blocks[i], baseStyle);
      if (spans.isEmpty) continue;
      final richText = selectable
          ? SelectableText.rich(TextSpan(children: spans, style: baseStyle))
          : RichText(text: TextSpan(children: spans, style: baseStyle));
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: i < blocks.length - 1 ? 8 : 0),
          child: richText,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 按 <p> 拆分段落，过滤空内容
  List<String> _parseBlocks(String html) {
    // 将 <br> 转为换行符，然后以 <p> 为段落分隔
    final normalized = html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</?p[^>]*>'), '\x00')
        .replaceAll(RegExp(r'</?div[^>]*>'), '\x00');

    return normalized
        .split('\x00')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// 解析段落内 <span style="color:…"> / <strong> / <em> 等内联标签
  List<InlineSpan> _parseInline(String html, TextStyle base) {
    final spans = <InlineSpan>[];
    final stack = <TextStyle>[base];
    int pos = 0;

    while (pos < html.length) {
      final tagOpen = html.indexOf('<', pos);
      if (tagOpen == -1) {
        // 剩余纯文本
        final text = _decode(html.substring(pos));
        if (text.isNotEmpty) spans.add(TextSpan(text: text, style: stack.last));
        break;
      }

      // 标签前的文本
      if (tagOpen > pos) {
        final text = _decode(html.substring(pos, tagOpen));
        if (text.isNotEmpty) spans.add(TextSpan(text: text, style: stack.last));
      }

      final tagClose = html.indexOf('>', tagOpen);
      if (tagClose == -1) break;

      final tag = html.substring(tagOpen + 1, tagClose).trim();
      pos = tagClose + 1;

      if (tag.startsWith('/')) {
        // 闭合标签：弹出样式栈
        if (stack.length > 1) stack.removeLast();
      } else if (tag.startsWith('span')) {
        // 提取 color 内联样式
        final colorMatch =
            RegExp(r'color\s*:\s*#([0-9A-Fa-f]{6})').firstMatch(tag);
        if (colorMatch != null) {
          final hex = colorMatch.group(1)!;
          final color = Color(int.parse('FF$hex', radix: 16));
          stack.add(stack.last.copyWith(color: color));
        } else {
          stack.add(stack.last); // 无颜色：继承当前样式
        }
      } else if (tag == 'strong' || tag == 'b') {
        stack.add(stack.last.copyWith(fontWeight: FontWeight.bold));
      } else if (tag == 'em' || tag == 'i') {
        stack.add(stack.last.copyWith(fontStyle: FontStyle.italic));
      } else if (tag == 'u') {
        stack.add(stack.last
            .copyWith(decoration: TextDecoration.underline));
      } else if (tag.startsWith('br')) {
        spans.add(const TextSpan(text: '\n'));
      }
      // 其他标签（img 等）：忽略
    }

    return spans;
  }

  String _decode(String s) {
    return s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}
