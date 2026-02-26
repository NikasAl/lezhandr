import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'auto_scaling_math.dart';

/// Widget that renders Markdown text with LaTeX math formula support.
///
/// Supports:
/// - Headers: # H1, ## H2, ### H3
/// - Bold: **text** or __text__
/// - Italic: *text* or _text_
/// - Inline code: `code`
/// - Bullet lists: - item or * item
/// - Numbered lists: 1. item
/// - Inline formulas: `$E = mc^2$` or `\(E = mc^2\)`
/// - Display (block) formulas: `$$\int_a^b f(x)dx$$`
class MarkdownWithMath extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final bool selectable;
  final int? maxLines;
  final TextOverflow? overflow;

  const MarkdownWithMath({
    super.key,
    required this.text,
    this.textStyle,
    this.selectable = true,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(text);
    
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handle maxLines truncation
    if (maxLines != null) {
      return _buildTruncated(context, blocks);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map((block) => _buildBlock(context, block)).toList(),
    );
  }

  Widget _buildTruncated(BuildContext context, List<_Block> blocks) {
    final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
    final spans = <InlineSpan>[];
    int lineCount = 0;
    bool exceeded = false;

    for (final block in blocks) {
      if (exceeded) break;

      if (block is _DisplayMathBlock) {
        lineCount += 2;
        if (lineCount > maxLines!) {
          exceeded = true;
          break;
        }
        final mathStyle = baseStyle.copyWith(
          fontFamily: null,
          fontSize: (baseStyle.fontSize ?? 14) * 1.15,
        );
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(block.formula, textStyle: mathStyle),
        ));
        spans.add(const TextSpan(text: '\n'));
      } else if (block is _TextBlock) {
        final blockSpans = _buildInlineSpans(context, block.content, baseStyle, truncate: maxLines! - lineCount);
        if (blockSpans != null) {
          spans.addAll(blockSpans.spans);
          lineCount += blockSpans.linesUsed;
          if (blockSpans.truncated) {
            exceeded = true;
          }
        }
      } else if (block is _HeaderBlock) {
        lineCount += 1;
        if (lineCount > maxLines!) {
          exceeded = true;
          break;
        }
        final headerStyle = _getHeaderStyle(baseStyle, block.level);
        spans.add(TextSpan(text: block.content, style: headerStyle));
        spans.add(const TextSpan(text: '\n'));
      } else if (block is _ListBlock) {
        for (final item in block.items) {
          lineCount += 1;
          if (lineCount > maxLines!) {
            exceeded = true;
            break;
          }
          spans.add(const TextSpan(text: '• '));
          final itemSpans = _buildInlineSpans(context, item, baseStyle);
          if (itemSpans != null) {
            spans.addAll(itemSpans.spans);
          }
          spans.add(const TextSpan(text: '\n'));
        }
      }
    }

    return Text.rich(
      TextSpan(children: spans, style: baseStyle),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }

  Widget _buildBlock(BuildContext context, _Block block) {
    final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;

    if (block is _DisplayMathBlock) {
      final mathStyle = baseStyle.copyWith(
        fontFamily: null,
        fontSize: (baseStyle.fontSize ?? 14) * 1.25,
      );
      return FittedMath(
        latex: block.formula,
        textStyle: mathStyle,
        mathStyle: MathStyle.display,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      );
    } else if (block is _HeaderBlock) {
      final headerStyle = _getHeaderStyle(baseStyle, block.level);
      return Padding(
        padding: EdgeInsets.only(top: block.level == 1 ? 0 : 8, bottom: 4),
        child: Text(
          block.content,
          style: headerStyle,
        ),
      );
    } else if (block is _ListBlock) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.ordered ? '${block.items.indexOf(item) + 1}.' : '•',
                      style: baseStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInlineWidget(context, item, baseStyle),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    } else if (block is _CodeBlock) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          block.content,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            color: Colors.grey[200],
            fontSize: (baseStyle.fontSize ?? 14) * 0.9,
          ),
        ),
      );
    } else if (block is _TextBlock) {
      return _buildInlineWidget(context, block.content, baseStyle);
    }

    return const SizedBox.shrink();
  }

  TextStyle _getHeaderStyle(TextStyle base, int level) {
    final sizes = {1: 1.5, 2: 1.3, 3: 1.15, 4: 1.0, 5: 0.9, 6: 0.85};
    final factor = sizes[level] ?? 1.0;
    return base.copyWith(
      fontSize: (base.fontSize ?? 14) * factor,
      fontWeight: FontWeight.bold,
      height: 1.3,
    );
  }

  Widget _buildInlineWidget(BuildContext context, String text, TextStyle baseStyle) {
    final result = _buildInlineSpans(context, text, baseStyle);
    if (result == null || result.spans.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text.rich(
      TextSpan(children: result.spans, style: baseStyle),
    );
  }

  _SpanResult? _buildInlineSpans(BuildContext context, String text, TextStyle baseStyle, {int? truncate}) {
    final spans = <InlineSpan>[];
    final segments = _parseInlineSegments(text);
    int linesUsed = 0;
    bool truncated = false;

    for (final seg in segments) {
      if (truncated) break;
      
      if (seg is _TextSegment) {
        final styledSpans = _parseMarkdownInline(seg.content, baseStyle);
        if (truncate != null) {
          // Count newlines
          final newlineCount = '\n'.allMatches(seg.content).length;
          if (linesUsed + newlineCount >= truncate) {
            truncated = true;
            // Truncate the text
            final lines = seg.content.split('\n');
            final remaining = truncate - linesUsed;
            if (remaining > 0 && remaining <= lines.length) {
              spans.add(TextSpan(
                text: lines.take(remaining).join('\n'),
                style: baseStyle,
              ));
            }
            break;
          }
          linesUsed += newlineCount;
        }
        spans.addAll(styledSpans);
      } else if (seg is _InlineMathSegment) {
        final mathStyle = baseStyle.copyWith(
          fontFamily: null,
          fontSize: (baseStyle.fontSize ?? 14) * 1.1,
        );
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Math.tex(
              seg.formula,
              textStyle: mathStyle,
              mathStyle: MathStyle.text,
            ),
          ),
        ));
      }
    }

    return spans.isEmpty ? null : _SpanResult(spans, linesUsed, truncated);
  }

  /// Parse inline markdown formatting (bold, italic, code)
  List<InlineSpan> _parseMarkdownInline(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    
    // Pattern for bold (**text** or __text__), italic (*text* or _text_), and code (`code`)
    // Also handle ***bold italic***
    final pattern = RegExp(
      r'(`+)([^`]+)\1|'  // code
      r'\*{3}(.+?)\*{3}|'  // ***bold italic***
      r'_{3}(.+?)_{3}|'    // ___bold italic___
      r'\*{2}(.+?)\*{2}|'  // **bold**
      r'_{2}(.+?)_{2}|'    // __bold__
      r'\*(.+?)\*|'        // *italic*
      r'_(.+?)_',          // _italic_
    );

    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Add plain text before this match
      if (match.start > lastEnd) {
        final before = text.substring(lastEnd, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before, style: baseStyle));
        }
      }

      // Determine which pattern matched and apply style
      if (match.group(1) != null) {
        // Code (`code`)
        spans.add(TextSpan(
          text: match.group(2)!,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            fontSize: (baseStyle.fontSize ?? 14) * 0.9,
          ),
        ));
      } else if (match.group(3) != null || match.group(4) != null) {
        // Bold + italic
        final content = match.group(3) ?? match.group(4)!;
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(5) != null || match.group(6) != null) {
        // Bold
        final content = match.group(5) ?? match.group(6)!;
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(7) != null || match.group(8) != null) {
        // Italic
        final content = match.group(7) ?? match.group(8)!;
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      if (remaining.isNotEmpty) {
        spans.add(TextSpan(text: remaining, style: baseStyle));
      }
    }

    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  /// Parse text into blocks (headers, lists, paragraphs, display math, code blocks)
  List<_Block> _parseBlocks(String input) {
    final blocks = <_Block>[];
    final lines = input.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Check for display math ($$...$$)
      if (line.trim().startsWith(r'$$')) {
        final formulaLines = <String>[];
        if (line.trim() == r'$$') {
          // Multi-line formula
          i++;
          while (i < lines.length && lines[i].trim() != r'$$') {
            formulaLines.add(lines[i]);
            i++;
          }
        } else {
          // Single line formula: $$formula$$
          final match = RegExp(r'\$\$(.+)\$\$').firstMatch(line.trim());
          if (match != null) {
            formulaLines.add(match.group(1)!);
          }
        }
        blocks.add(_DisplayMathBlock(formulaLines.join('\n')));
        i++;
        continue;
      }

      // Check for code block (```)
      if (line.trim().startsWith('```')) {
        i++; // Skip opening ```
        final codeLines = <String>[];
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        blocks.add(_CodeBlock(codeLines.join('\n')));
        i++; // Skip closing ```
        continue;
      }

      // Check for header (# )
      final headerMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        final content = headerMatch.group(2)!;
        blocks.add(_HeaderBlock(content, level));
        i++;
        continue;
      }

      // Check for list item (- or * or 1.)
      final listMatch = RegExp(r'^(\s*)[-*]\s+(.+)$').firstMatch(line);
      final orderedListMatch = RegExp(r'^(\s*)\d+\.\s+(.+)$').firstMatch(line);
      
      if (listMatch != null || orderedListMatch != null) {
        final items = <String>[];
        final isOrdered = orderedListMatch != null;
        
        while (i < lines.length) {
          final currentLine = lines[i];
          final itemMatch = isOrdered
              ? RegExp(r'^(\s*)\d+\.\s+(.+)$').firstMatch(currentLine)
              : RegExp(r'^(\s*)[-*]\s+(.+)$').firstMatch(currentLine);
          
          if (itemMatch != null) {
            items.add(itemMatch.group(2)!);
            i++;
          } else if (currentLine.trim().isEmpty) {
            i++;
          } else {
            break;
          }
        }
        
        if (items.isNotEmpty) {
          blocks.add(_ListBlock(items, isOrdered));
        }
        continue;
      }

      // Empty line - skip
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Regular paragraph - collect until empty line or special block
      final paragraphLines = <String>[];
      while (i < lines.length) {
        final currentLine = lines[i];
        if (currentLine.trim().isEmpty ||
            currentLine.trim().startsWith(r'$$') ||
            currentLine.trim().startsWith('```') ||
            RegExp(r'^#{1,6}\s+').hasMatch(currentLine) ||
            RegExp(r'^(\s*)[-*]\s+').hasMatch(currentLine) ||
            RegExp(r'^(\s*)\d+\.\s+').hasMatch(currentLine)) {
          break;
        }
        paragraphLines.add(currentLine);
        i++;
      }

      if (paragraphLines.isNotEmpty) {
        blocks.add(_TextBlock(paragraphLines.join('\n')));
      }
    }

    return blocks;
  }

  /// Parse inline segments (text and inline math)
  /// Supports both $...$ and \(...\) for inline LaTeX
  List<_InlineSegment> _parseInlineSegments(String text) {
    final segments = <_InlineSegment>[];
    // Match $...$ or \(...\)
    // Group 1: $formula$, Group 2: \(formula\)
    final pattern = RegExp(r'\$([^\$\n]+?)\$|\\\(([\s\S]+?)\\\)');
    
    int lastEnd = 0;
    
    for (final match in pattern.allMatches(text)) {
      // Add text before this match
      if (match.start > lastEnd) {
        final before = text.substring(lastEnd, match.start);
        if (before.isNotEmpty) {
          segments.add(_TextSegment(before));
        }
      }
      
      // Add math segment - check which group matched
      final formula = match.group(1) ?? match.group(2)!;
      segments.add(_InlineMathSegment(formula));
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      if (remaining.isNotEmpty) {
        segments.add(_TextSegment(remaining));
      }
    }
    
    return segments.isEmpty ? [_TextSegment(text)] : segments;
  }
}

/// Block types
abstract class _Block {}

class _TextBlock extends _Block {
  final String content;
  _TextBlock(this.content);
}

class _HeaderBlock extends _Block {
  final String content;
  final int level;
  _HeaderBlock(this.content, this.level);
}

class _ListBlock extends _Block {
  final List<String> items;
  final bool ordered;
  _ListBlock(this.items, this.ordered);
}

class _CodeBlock extends _Block {
  final String content;
  _CodeBlock(this.content);
}

class _DisplayMathBlock extends _Block {
  final String formula;
  _DisplayMathBlock(this.formula);
}

/// Inline segment types
abstract class _InlineSegment {}

class _TextSegment extends _InlineSegment {
  final String content;
  _TextSegment(this.content);
}

class _InlineMathSegment extends _InlineSegment {
  final String formula;
  _InlineMathSegment(this.formula);
}

/// Result of parsing inline spans
class _SpanResult {
  final List<InlineSpan> spans;
  final int linesUsed;
  final bool truncated;
  _SpanResult(this.spans, this.linesUsed, this.truncated);
}

/// A simpler widget for just math formulas (without markdown)
class MathFormula extends StatelessWidget {
  final String formula;
  final bool isDisplay;
  final TextStyle? textStyle;
  final Alignment alignment;

  const MathFormula({
    super.key,
    required this.formula,
    this.isDisplay = false,
    this.textStyle,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Math.tex(
        formula,
        textStyle: textStyle?.copyWith(fontFamily: null) ??
            DefaultTextStyle.of(context).style.copyWith(fontFamily: null),
        mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
      ),
    );
  }
}
