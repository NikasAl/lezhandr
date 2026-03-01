import 'package:flutter/material.dart';

/// Adaptive layout wrapper that constrains content width on wide screens
/// and centers it horizontally.
class AdaptiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const AdaptiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 600;

    if (isWideScreen) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      );
    }

    return padding != null ? Padding(padding: padding!, child: child) : child;
  }
}

/// Extension to easily check if screen is wide
extension ScreenSizeExtension on BuildContext {
  bool get isWideScreen => MediaQuery.of(this).size.width >= 600;
  double get screenWidth => MediaQuery.of(this).size.width;
}
