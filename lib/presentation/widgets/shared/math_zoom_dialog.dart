import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Dialog that displays a math formula in a larger, zoomable view.
/// Allows the user to see small formulas that were scaled down to fit.
class MathZoomDialog extends StatefulWidget {
  final String latex;
  final String? title;

  const MathZoomDialog({
    super.key,
    required this.latex,
    this.title,
  });

  /// Shows the zoom dialog for a formula
  static Future<void> show(BuildContext context, {
    required String latex,
    String? title,
  }) {
    return showDialog(
      context: context,
      builder: (context) => MathZoomDialog(
        latex: latex,
        title: title,
      ),
    );
  }

  @override
  State<MathZoomDialog> createState() => _MathZoomDialogState();
}

class _MathZoomDialogState extends State<MathZoomDialog> {
  double _scale = 1.0;
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.functions,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title ?? 'Формула',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
            ),

            const Divider(),

            // Formula view with zoom
            Flexible(
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 0.5,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(32),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Math.tex(
                    widget.latex,
                    textStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontFamily: null,
                      fontWeight: FontWeight.normal,
                    ),
                    mathStyle: MathStyle.display,
                  ),
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Zoom out
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: _scale > 0.5
                        ? () {
                            setState(() {
                              _scale = (_scale - 0.25).clamp(0.5, 3.0);
                              _controller.value = Matrix4.identity()..scale(_scale);
                            });
                          }
                        : null,
                    tooltip: 'Уменьшить',
                  ),
                  const SizedBox(width: 8),
                  // Scale indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(_scale * 100).round()}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Zoom in
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: _scale < 3.0
                        ? () {
                            setState(() {
                              _scale = (_scale + 0.25).clamp(0.5, 3.0);
                              _controller.value = Matrix4.identity()..scale(_scale);
                            });
                          }
                        : null,
                    tooltip: 'Увеличить',
                  ),
                  const SizedBox(width: 16),
                  // Reset
                  TextButton.icon(
                    icon: const Icon(Icons.fit_screen, size: 18),
                    label: const Text('Сброс'),
                    onPressed: () {
                      setState(() {
                        _scale = 1.0;
                        _controller.value = Matrix4.identity();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
