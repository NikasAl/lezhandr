import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_fork/src/ast/syntax_tree.dart';

/// Widget that automatically scales LaTeX formulas to fit available width.
///
/// This widget solves the overflow problem with flutter_math_fork when
/// formulas are wider than the available space. It uses several strategies:
///
/// 1. First, try to render at natural size
/// 2. If overflow detected, scale down with FittedBox
/// 3. If still too small, provide horizontal scrolling
class AutoScalingMath extends StatefulWidget {
  final String latex;
  final TextStyle? textStyle;
  final MathStyle mathStyle;
  final double minScaleFactor;
  final double maxScaleFactor;
  final bool enableScrolling;
  final EdgeInsets padding;

  const AutoScalingMath({
    super.key,
    required this.latex,
    this.textStyle,
    this.mathStyle = MathStyle.display,
    this.minScaleFactor = 0.5,
    this.maxScaleFactor = 1.0,
    this.enableScrolling = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<AutoScalingMath> createState() => _AutoScalingMathState();
}

class _AutoScalingMathState extends State<AutoScalingMath> {
  final GlobalKey _mathKey = GlobalKey();
  Size? _measuredSize;
  bool _hasOverflow = false;
  double _scaleFactor = 1.0;

  @override
  void didUpdateWidget(AutoScalingMath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latex != widget.latex ||
        oldWidget.textStyle != widget.textStyle ||
        oldWidget.mathStyle != widget.mathStyle) {
      _measuredSize = null;
      _hasOverflow = false;
      _scaleFactor = 1.0;
    }
  }

  void _checkOverflow(BoxConstraints constraints) {
    if (_measuredSize != null) {
      final hasOverflow = _measuredSize!.width > constraints.maxWidth;
      if (hasOverflow != _hasOverflow) {
        setState(() {
          _hasOverflow = hasOverflow;
          if (hasOverflow) {
            // Calculate scale factor to fit
            _scaleFactor = (constraints.maxWidth / _measuredSize!.width)
                .clamp(widget.minScaleFactor, widget.maxScaleFactor);
          } else {
            _scaleFactor = 1.0;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If we haven't measured yet, render to measure
        if (_measuredSize == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _measureSize(constraints);
          });
        } else {
          _checkOverflow(constraints);
        }

        final mathWidget = Padding(
          padding: widget.padding,
          child: Math.tex(
            widget.latex,
            key: _mathKey,
            textStyle: widget.textStyle?.copyWith(fontFamily: null) ??
                DefaultTextStyle.of(context).style.copyWith(fontFamily: null),
            mathStyle: widget.mathStyle,
          ),
        );

        // If no overflow, render normally
        if (!_hasOverflow || _scaleFactor >= 1.0) {
          return mathWidget;
        }

        // If scaling would make it too small and scrolling is enabled
        if (_scaleFactor < widget.minScaleFactor && widget.enableScrolling) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: mathWidget,
          );
        }

        // Scale to fit
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: mathWidget,
        );
      },
    );
  }

  void _measureSize(BoxConstraints constraints) {
    final renderObject =
        _mathKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderObject != null && mounted) {
      final size = renderObject.size;
      if (size != _measuredSize) {
        setState(() {
          _measuredSize = size;
          _hasOverflow = size.width > constraints.maxWidth;
          if (_hasOverflow) {
            _scaleFactor = (constraints.maxWidth / size.width)
                .clamp(widget.minScaleFactor, widget.maxScaleFactor);
          }
        });
      }
    }
  }
}

/// A simpler approach using FittedBox with alignment.
///
/// This is a stateless widget that always uses FittedBox to ensure
/// the formula fits. Use this when you want simpler behavior.
class FittedMath extends StatelessWidget {
  final String latex;
  final TextStyle? textStyle;
  final MathStyle mathStyle;
  final Alignment alignment;
  final EdgeInsets padding;

  const FittedMath({
    super.key,
    required this.latex,
    this.textStyle,
    this.mathStyle = MathStyle.display,
    this.alignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Math.tex(
          latex,
          textStyle: textStyle?.copyWith(fontFamily: null) ??
              DefaultTextStyle.of(context).style.copyWith(fontFamily: null),
          mathStyle: mathStyle,
        ),
      ),
    );
  }
}

/// A scrollable math widget for very long formulas.
///
/// This wraps the formula in a horizontal scroll view when needed.
class ScrollableMath extends StatelessWidget {
  final String latex;
  final TextStyle? textStyle;
  final MathStyle mathStyle;
  final EdgeInsets padding;
  final double? maxWidth;

  const ScrollableMath({
    super.key,
    required this.latex,
    this.textStyle,
    this.mathStyle = MathStyle.display,
    this.padding = EdgeInsets.zero,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final mathWidget = Math.tex(
      latex,
      textStyle: textStyle?.copyWith(fontFamily: null) ??
          DefaultTextStyle.of(context).style.copyWith(fontFamily: null),
      mathStyle: mathStyle,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: maxWidth != null
          ? ConstrainedBox(
              constraints: BoxConstraints(minWidth: maxWidth!),
              child: mathWidget,
            )
          : mathWidget,
    );
  }
}

/// Intelligent math widget that combines multiple strategies:
/// - First tries to fit with natural size
/// - If too wide, scales down to a minimum size
/// - If still too wide, enables scrolling
class SmartMath extends StatelessWidget {
  final String latex;
  final TextStyle? textStyle;
  final MathStyle mathStyle;
  final double minFontSize;
  final EdgeInsets padding;

  const SmartMath({
    super.key,
    required this.latex,
    this.textStyle,
    this.mathStyle = MathStyle.display,
    this.minFontSize = 8.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;
    final naturalFontSize = baseStyle.fontSize ?? 14.0;

    // If minimum font size is close to natural, just use FittedBox
    if (minFontSize >= naturalFontSize * 0.7) {
      return FittedMath(
        latex: latex,
        textStyle: textStyle,
        mathStyle: mathStyle,
        padding: padding,
      );
    }

    // Use LayoutBuilder to make smart decisions
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate minimum scale based on font sizes
        final minScale = minFontSize / naturalFontSize;

        return _SmartMathContent(
          latex: latex,
          textStyle: baseStyle,
          mathStyle: mathStyle,
          minScale: minScale,
          padding: padding,
          availableWidth: constraints.maxWidth,
        );
      },
    );
  }
}

class _SmartMathContent extends StatefulWidget {
  final String latex;
  final TextStyle textStyle;
  final MathStyle mathStyle;
  final double minScale;
  final EdgeInsets padding;
  final double availableWidth;

  const _SmartMathContent({
    required this.latex,
    required this.textStyle,
    required this.mathStyle,
    required this.minScale,
    required this.padding,
    required this.availableWidth,
  });

  @override
  State<_SmartMathContent> createState() => _SmartMathContentState();
}

class _SmartMathContentState extends State<_SmartMathContent> {
  final GlobalKey _key = GlobalKey();
  Size? _size;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(_SmartMathContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latex != widget.latex ||
        oldWidget.textStyle != widget.textStyle ||
        oldWidget.availableWidth != widget.availableWidth) {
      _measured = false;
      _size = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && mounted) {
      setState(() {
        _size = box.size;
        _measured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mathWidget = Padding(
      padding: widget.padding,
      child: Math.tex(
        widget.latex,
        key: _key,
        textStyle: widget.textStyle.copyWith(fontFamily: null),
        mathStyle: widget.mathStyle,
      ),
    );

    if (!_measured || _size == null) {
      return Opacity(opacity: 0.0, child: mathWidget);
    }

    final overflow = _size!.width > widget.availableWidth;

    if (!overflow) {
      return mathWidget;
    }

    // Calculate required scale
    final requiredScale = widget.availableWidth / _size!.width;

    if (requiredScale < widget.minScale) {
      // Too small to scale, use scrolling
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: mathWidget,
      );
    }

    // Scale to fit
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: mathWidget,
    );
  }
}
