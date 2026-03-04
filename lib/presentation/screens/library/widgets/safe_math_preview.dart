import 'package:flutter/material.dart';
import '../../../widgets/shared/markdown_with_math.dart';

/// Safe math preview widget with error handling for LaTeX rendering
class SafeMathPreview extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SafeMathPreview({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Try to render with LaTeX, fall back to plain text on error
    try {
      return MarkdownWithMath(
        text: text,
        textStyle: style,
        // No maxLines - let content take as much space as needed
      );
    } catch (e) {
      // Fallback: show plain text without $ symbols
      return Text(
        text.replaceAll(RegExp(r'\$+'), ''),  // Remove $ symbols
        style: style,
        // No maxLines - let content take as much space as needed
      );
    }
  }
}
