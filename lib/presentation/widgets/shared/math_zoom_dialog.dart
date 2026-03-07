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

            // Formula view with pinch-to-zoom and pan
            Expanded(
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.3,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  constrained: false,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
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

            // Hint about gestures
            _buildHint(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
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
              overflow: TextOverflow.ellipsis,
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

  Widget _buildHint(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Icon(
            Icons.pinch,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Text(
            'Щипок — масштабирование',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '•',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Icon(
            Icons.pan_tool,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Text(
            'Перетаскивание — перемещение',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
