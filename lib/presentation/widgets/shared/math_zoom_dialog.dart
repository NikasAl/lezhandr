import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Dialog that displays a math formula in a zoomable view.
/// Supports pinch-to-zoom and pan gestures for easy reading of long formulas.
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
  final TransformationController _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformController.value = Matrix4.identity();
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.85,
        child: Column(
          children: [
            // Header
            _buildHeader(theme),
            const Divider(height: 1),

            // Formula view with pinch-to-zoom and pan
            Expanded(
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.3,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  constrained: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
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
              ),
            ),

            // Controls
            _buildControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          Icon(
            Icons.functions,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ?? 'Формула',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Зажмите и растяните для увеличения',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Закрыть',
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Zoom out button
          IconButton.outlined(
            icon: const Icon(Icons.remove),
            onPressed: () {
              final currentScale = _transformController.value.getMaxScaleOnAxis();
              final newScale = (currentScale - 0.25).clamp(0.3, 5.0);
              _transformController.value = Matrix4.identity()..scale(newScale);
            },
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
              'Свайп для зума',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          // Zoom in button
          IconButton.outlined(
            icon: const Icon(Icons.add),
            onPressed: () {
              final currentScale = _transformController.value.getMaxScaleOnAxis();
              final newScale = (currentScale + 0.25).clamp(0.3, 5.0);
              _transformController.value = Matrix4.identity()..scale(newScale);
            },
            tooltip: 'Увеличить',
          ),
          const SizedBox(width: 16),
          // Reset
          TextButton.icon(
            icon: const Icon(Icons.fit_screen, size: 18),
            label: const Text('Сброс'),
            onPressed: _resetView,
          ),
        ],
      ),
    );
  }
}
