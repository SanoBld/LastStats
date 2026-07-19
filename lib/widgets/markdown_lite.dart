// lib/widgets/markdown_lite.dart
//
// Minimal markdown renderer for short texts (release notes, news items).
// Supports: **bold**, *italic*/_italic_, `code`, "- " / "* " bullet lists,
// "# " / "## " headers, and auto-linked URLs. No external package needed.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownLite extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color linkColor;

  const MarkdownLite({
    super.key,
    required this.text,
    required this.style,
    required this.linkColor,
  });

  static final RegExp _urlRegex =
      RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
  // Inline tokens, order matters (checked left to right per match position).
  static final RegExp _boldRegex   = RegExp(r'\*\*(.+?)\*\*');
  static final RegExp _italicRegex = RegExp(r'(?<!\*)\*(?!\*)(.+?)\*(?!\*)|_(.+?)_');
  static final RegExp _codeRegex   = RegExp(r'`([^`]+)`');

  Future<void> _openUrl(String rawUrl) async {
    final cleaned = rawUrl.replaceAll(RegExp(r'[)\].,;!?]+$'), '');
    final uri = Uri.tryParse(cleaned);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Parses one line into inline spans (bold / italic / code / links).
  InlineSpan _parseInline(String line) {
    final tokens = <_Token>[
      ..._urlRegex.allMatches(line).map((m) => _Token(m.start, m.end, _TokType.url, m.group(0)!)),
      ..._boldRegex.allMatches(line).map((m) => _Token(m.start, m.end, _TokType.bold, m.group(1)!)),
      ..._codeRegex.allMatches(line).map((m) => _Token(m.start, m.end, _TokType.code, m.group(1)!)),
      ..._italicRegex.allMatches(line).map((m) => _Token(m.start, m.end, _TokType.italic, m.group(1) ?? m.group(2) ?? '')),
    ]..sort((a, b) => a.start.compareTo(b.start));

    // Remove overlaps, first match wins.
    final cleaned = <_Token>[];
    int lastEnd = 0;
    for (final t in tokens) {
      if (t.start < lastEnd) continue;
      cleaned.add(t);
      lastEnd = t.end;
    }

    if (cleaned.isEmpty) return TextSpan(text: line);

    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final t in cleaned) {
      if (t.start > cursor) spans.add(TextSpan(text: line.substring(cursor, t.start)));
      switch (t.type) {
        case _TokType.url:
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline:  TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _openUrl(t.text),
              child: Text(t.text, style: style?.copyWith(
                color: linkColor, fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline, decorationColor: linkColor,
              )),
            ),
          ));
          break;
        case _TokType.bold:
          spans.add(TextSpan(text: t.text, style: const TextStyle(fontWeight: FontWeight.w800)));
          break;
        case _TokType.italic:
          spans.add(TextSpan(text: t.text, style: const TextStyle(fontStyle: FontStyle.italic)));
          break;
        case _TokType.code:
          spans.add(TextSpan(
            text: t.text,
            style: const TextStyle(fontFamily: 'monospace'),
          ));
          break;
      }
      cursor = t.end;
    }
    if (cursor < line.length) spans.add(TextSpan(text: line.substring(cursor)));
    return TextSpan(style: style, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Headers: "## Title" -> bold, slightly bigger.
      final headerMatch = RegExp(r'^(#{1,3})\s+(.*)').firstMatch(line);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        final content = headerMatch.group(2)!;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text.rich(_parseInline(content),
              style: style?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: (style?.fontSize ?? 14) + (level == 1 ? 4 : level == 2 ? 2 : 1),
              )),
        ));
        continue;
      }

      // Bullet lists: "- item" or "* item"
      final bulletMatch = RegExp(r'^[-*]\s+(.*)').firstMatch(line);
      if (bulletMatch != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('•  ', style: style),
            Expanded(child: Text.rich(_parseInline(bulletMatch.group(1)!), style: style)),
          ]),
        ));
        continue;
      }

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text.rich(_parseInline(line), style: style),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

enum _TokType { url, bold, italic, code }

class _Token {
  final int start, end;
  final _TokType type;
  final String text;
  _Token(this.start, this.end, this.type, this.text);
}
