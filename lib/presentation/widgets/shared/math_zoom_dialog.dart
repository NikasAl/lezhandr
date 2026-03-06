import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Dialog that displays a math formula in a larger, scrollable view.
/// Allows the user to see small formulas that were scaled down to fit.
/// Dialog height adapts to formula size (up to max screen height).
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
  final TransformationController _transformController = TransformationController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _transformController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _transformController.value = Matrix4.identity();
    });
    _horizontalController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    _verticalController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.85;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: maxHeight,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(theme),
              const Divider(height: 1),

              // Formula view - expands only as needed
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight - 180, // Reserve space for header + controls
                ),
                child: _buildFormulaView(theme),
              ),

              // Controls (fixed height at bottom)
              _buildControls(theme),
            ],
          ),
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
    );
  }

  Widget _buildFormulaView(ThemeData theme) {
    final mathWidget = Padding(
      padding: const EdgeInsets.all(32),
      child: Math.tex(
        widget.latex,
        textStyle: theme.textTheme.headlineMedium?.copyWith(
          fontFamily: null,
          fontWeight: FontWeight.normal,
        ),
        mathStyle: MathStyle.display,
      ),
    );

    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(64),
      constrained: false,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              child: mathWidget,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Padding(
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
                      _transformController.value = Matrix4.identity()..scale(_scale);
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
                      _transformController.value = Matrix4.identity()..scale(_scale);
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
            onPressed: _resetView,
          ),
        ],
      ),
    );
  }
}
