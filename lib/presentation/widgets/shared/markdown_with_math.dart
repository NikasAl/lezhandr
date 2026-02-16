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

    // Group segments: text + inlineMath together, displayMath separate
    final blocks = _groupIntoBlocks(segments);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map((block) => _buildBlock(context, block)).toList(),
    );
  }

  /// Group consecutive text and inlineMath segments into blocks
  /// Display math becomes its own block
  List<_SegmentBlock> _groupIntoBlocks(List<_TextSegment> segments) {
    final blocks = <_SegmentBlock>[];
    var currentInlineSegments = <_TextSegment>[];
    
    for (final segment in segments) {
      if (segment.type == _SegmentType.displayMath) {
        // Flush current inline block if any
        if (currentInlineSegments.isNotEmpty) {
          blocks.add(_SegmentBlock.inline(currentInlineSegments));
          currentInlineSegments = [];
        }
        // Display math is its own block
        blocks.add(_SegmentBlock.display(segment));
      } else {
        // Text or inline math - accumulate
        currentInlineSegments.add(segment);
      }
    }
    
    // Flush remaining inline segments
    if (currentInlineSegments.isNotEmpty) {
      blocks.add(_SegmentBlock.inline(currentInlineSegments));
    }
    
    return blocks;
  }
  
  Widget _buildBlock(BuildContext context, _SegmentBlock block) {
    if (block.isDisplay) {
      // Display math - separate centered block
      final segment = block.segments.first;
      final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
      final mathStyle = baseStyle.copyWith(
        fontFamily: null,
        fontSize: (baseStyle.fontSize ?? 14) * 1.25,
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
    } else {
      // Inline block - text with inline math using Text.rich
      return _buildInlineBlock(context, block.segments);
    }
  }
  
  Widget _buildInlineBlock(BuildContext context, List<_TextSegment> segments) {
    final spans = <InlineSpan>[];
    final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
    
    for (final segment in segments) {
      if (segment.type == _SegmentType.text) {
        if (segment.content.trim().isEmpty) continue;
        // Use MarkdownBody for text segments to preserve markdown formatting
        // But for inline flow, we need simpler approach
        spans.add(TextSpan(
          text: segment.content,
          style: baseStyle,
        ));
      } else if (segment.type == _SegmentType.inlineMath) {
        final mathStyle = baseStyle.copyWith(
          fontFamily: null,
          fontSize: (baseStyle.fontSize ?? 14) * 1.1,
        );
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            segment.content,
            textStyle: mathStyle,
            mathStyle: MathStyle.text,
          ),
        ));
      }
    }
    
    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
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

/// A block of segments (either inline content or display math)
class _SegmentBlock {
  final List<_TextSegment> segments;
  final bool isDisplay;

  _SegmentBlock._(this.segments, this.isDisplay);
  
  factory _SegmentBlock.inline(List<_TextSegment> segments) {
    return _SegmentBlock._(segments, false);
  }
  
  factory _SegmentBlock.display(_TextSegment segment) {
    return _SegmentBlock._([segment], true);
  }
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
