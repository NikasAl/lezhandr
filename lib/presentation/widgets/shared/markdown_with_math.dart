import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Widget that renders Markdown text with LaTeX math formula support.
///
/// Supports:
/// - Inline formulas: `$E = mc^2$`
/// - Display (block) formulas: `$$\int_a^b f(x)dx$$`
///
/// Uses flutter_math_fork for LaTeX rendering and flutter_markdown for
/// regular markdown content.
class MarkdownWithMath extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;
  final void Function(String, String, String)? onLinkTap;
  final int? maxLines;
  final TextOverflow? overflow;

  const MarkdownWithMath({
    super.key,
    required this.text,
    this.textStyle,
    this.selectable = true,
    this.styleSheet,
    this.onLinkTap,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _parseText(text);

    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    // If maxLines is specified, we need to handle it differently
    if (maxLines != null) {
      return _buildTruncatedContent(context, segments);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: segments.map((segment) => _buildSegment(context, segment)).toList(),
    );
  }

  Widget _buildTruncatedContent(BuildContext context, List<_TextSegment> segments) {
    // For truncated view, use a RichText-like approach
    final spans = <InlineSpan>[];
    int lineCount = 0;
    bool exceeded = false;

    for (final segment in segments) {
      if (exceeded) break;

      if (segment.type == _SegmentType.text) {
        // Count lines in text
        final textLines = '\n'.allMatches(segment.content).length + 1;
        if (lineCount + textLines > maxLines!) {
          exceeded = true;
          break;
        }
        lineCount += textLines;

        spans.add(TextSpan(
          text: segment.content,
          style: textStyle ?? DefaultTextStyle.of(context).style,
        ));
      } else if (segment.type == _SegmentType.inlineMath) {
        // Inline math as widget span with slightly larger font
        final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
        final mathStyle = baseStyle.copyWith(
          fontFamily: null,
          fontSize: (baseStyle.fontSize ?? 14) * 1.1,  // 10% larger for readability
        );
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            segment.content,
            textStyle: mathStyle,
          ),
        ));
      } else {
        // Display math - render inline in truncated view for compactness
        final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
        final mathStyle = baseStyle.copyWith(
          fontFamily: null,
          fontSize: (baseStyle.fontSize ?? 14) * 1.15,  // 15% larger for display math inline
        );
        lineCount += 1;
        if (lineCount > maxLines!) {
          exceeded = true;
          break;
        }
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            segment.content,
            textStyle: mathStyle,
          ),
        ));
      }
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: textStyle ?? DefaultTextStyle.of(context).style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }

  Widget _buildSegment(BuildContext context, _TextSegment segment) {
    switch (segment.type) {
      case _SegmentType.text:
        if (segment.content.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        return MarkdownBody(
          data: segment.content,
          selectable: selectable,
          styleSheet: styleSheet,
          onTapLink: onLinkTap != null
              ? (text, href, title) => onLinkTap!(text, href ?? '', title)
              : null,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

      case _SegmentType.inlineMath:
        final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
        final mathStyle = baseStyle.copyWith(
          fontFamily: null,
          fontSize: (baseStyle.fontSize ?? 14) * 1.1,  // 10% larger for readability
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Math.tex(
            segment.content,
            textStyle: mathStyle,
            mathStyle: MathStyle.text,
          ),
        );

      case _SegmentType.displayMath:
        final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
        final mathStyle = baseStyle.copyWith(
          fontFamily: null,
          fontSize: (baseStyle.fontSize ?? 14) * 1.25,  // 25% larger for display math
        );
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Math.tex(
              segment.content,
              textStyle: mathStyle,
              mathStyle: MathStyle.display,
            ),
          ),
        );
    }
  }

  /// Parses text into segments of different types
  List<_TextSegment> _parseText(String input) {
    final segments = <_TextSegment>[];

    // Pattern for display math ($$...$$) - must be checked first
    final displayMathPattern = RegExp(r'\$\$([\s\S]*?)\$\$');
    // Pattern for inline math ($...$)
    final inlineMathPattern = RegExp(r'\$([^\$\n]+?)\$');

    // Combine patterns with capture groups
    final combinedPattern = RegExp(
      r'\$\$([\s\S]*?)\$\$|\$([^\$\n]+?)\$',
    );

    int lastEnd = 0;

    for (final match in combinedPattern.allMatches(input)) {
      // Add text before this match
      if (match.start > lastEnd) {
        final beforeText = input.substring(lastEnd, match.start);
        if (beforeText.isNotEmpty) {
          segments.add(_TextSegment(beforeText, _SegmentType.text));
        }
      }

      // Determine which pattern matched
      if (match.group(1) != null) {
        // Display math ($$...$$)
        segments.add(_TextSegment(match.group(1)!, _SegmentType.displayMath));
      } else if (match.group(2) != null) {
        // Inline math ($...$)
        segments.add(_TextSegment(match.group(2)!, _SegmentType.inlineMath));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < input.length) {
      final remainingText = input.substring(lastEnd);
      if (remainingText.isNotEmpty) {
        segments.add(_TextSegment(remainingText, _SegmentType.text));
      }
    }

    // Merge consecutive text segments
    return _mergeTextSegments(segments);
  }

  List<_TextSegment> _mergeTextSegments(List<_TextSegment> segments) {
    if (segments.isEmpty) return segments;

    final merged = <_TextSegment>[];
    var currentText = StringBuffer();

    for (final segment in segments) {
      if (segment.type == _SegmentType.text) {
        currentText.write(segment.content);
      } else {
        if (currentText.isNotEmpty) {
          merged.add(_TextSegment(currentText.toString(), _SegmentType.text));
          currentText.clear();
        }
        merged.add(segment);
      }
    }

    if (currentText.isNotEmpty) {
      merged.add(_TextSegment(currentText.toString(), _SegmentType.text));
    }

    return merged;
  }
}

/// Segment types for parsing
enum _SegmentType {
  text,
  inlineMath,
  displayMath,
}

/// A parsed text segment
class _TextSegment {
  final String content;
  final _SegmentType type;

  _TextSegment(this.content, this.type);
}

/// A simpler widget for just math formulas (without markdown)
class MathFormula extends StatelessWidget {
  final String formula;
  final bool isDisplay;
  final TextStyle? textStyle;

  const MathFormula({
    super.key,
    required this.formula,
    this.isDisplay = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Math.tex(
      formula,
      textStyle: textStyle?.copyWith(fontFamily: null) ??
          DefaultTextStyle.of(context).style.copyWith(fontFamily: null),
      mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
    );
  }
}
