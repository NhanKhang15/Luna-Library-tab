import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Device size breakpoints
class Breakpoints {
  static const double smallPhone = 360;
  static const double standardPhone = 400;
  static const double largePhone = 480;
  static const double tablet = 600;
  static const double desktop = 900;
}

/// Responsive sizing utilities
class ResponsiveUtils {
  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Check if keyboard is open
  static bool isKeyboardOpen(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 0;

  /// Get keyboard height
  static double keyboardHeight(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom;

  /// Get safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  /// Check device type
  static bool isSmallPhone(BuildContext context) =>
      screenWidth(context) < Breakpoints.smallPhone;

  static bool isStandardPhone(BuildContext context) =>
      screenWidth(context) >= Breakpoints.smallPhone &&
      screenWidth(context) < Breakpoints.largePhone;

  static bool isLargePhone(BuildContext context) =>
      screenWidth(context) >= Breakpoints.largePhone &&
      screenWidth(context) < Breakpoints.tablet;

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= Breakpoints.tablet;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Get responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < Breakpoints.smallPhone) return 16;
    if (width < Breakpoints.standardPhone) return 20;
    if (width < Breakpoints.largePhone) return 24;
    if (width < Breakpoints.tablet) return 32;
    return 48; // Tablets
  }

  /// Get responsive card max width
  static double cardMaxWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < Breakpoints.smallPhone) return width - 32;
    if (width < Breakpoints.standardPhone) return width - 40;
    if (width < Breakpoints.largePhone) return math.min(width - 48, 400);
    if (width < Breakpoints.tablet) return math.min(width - 64, 420);
    return 480; // Cap for tablets
  }

  /// Get responsive vertical spacing
  static double verticalSpacing(BuildContext context, {double base = 1.0}) {
    final height = screenHeight(context);
    final factor = height < 700 ? 0.8 : (height > 900 ? 1.2 : 1.0);
    return base * factor;
  }

  /// Clamp font size for accessibility
  static double clampedFontSize(
    BuildContext context,
    double baseSize, {
    double minSize = 10,
    double maxSize = 32,
  }) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final scaled = baseSize * textScale;
    return scaled.clamp(minSize, maxSize);
  }

  /// Get responsive logo size
  static double logoSize(BuildContext context) {
    final width = screenWidth(context);
    final height = screenHeight(context);
    final isSmall = height < 700 || width < Breakpoints.smallPhone;
    if (isSmall) return 70;
    if (width >= Breakpoints.tablet) return 110;
    return 90;
  }

  /// Get responsive button height
  static double buttonHeight(BuildContext context) {
    final height = screenHeight(context);
    if (height < 700) return 48;
    return 52;
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? horizontalOverride;
  final double? verticalOverride;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontalOverride,
    this.verticalOverride,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal =
        horizontalOverride ?? ResponsiveUtils.horizontalPadding(context);
    final vertical = verticalOverride ?? 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: child,
    );
  }
}

/// Container with max width constraint (for tablets)
class ResponsiveMaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidthOverride;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const ResponsiveMaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidthOverride,
    this.padding,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        maxWidthOverride ?? ResponsiveUtils.cardMaxWidth(context);

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Responsive spacer that adapts to screen size
class ResponsiveSpacer extends StatelessWidget {
  final double baseHeight;
  final double? minHeight;

  const ResponsiveSpacer({
    super.key,
    required this.baseHeight,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveUtils.screenHeight(context);
    final factor = height < 700 ? 0.7 : (height > 900 ? 1.2 : 1.0);
    final computed = baseHeight * factor;
    final finalHeight = minHeight != null
        ? math.max(computed, minHeight!)
        : computed;

    return SizedBox(height: finalHeight);
  }
}

/// Keyboard-aware scroll view that handles keyboard appearance
class KeyboardAwareScrollView extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const KeyboardAwareScrollView({
    super.key,
    required this.child,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = ResponsiveUtils.keyboardHeight(context);
    final bottomPadding = keyboardHeight > 0 ? keyboardHeight : 0.0;

    return SingleChildScrollView(
      controller: controller,
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding?.add(EdgeInsets.only(bottom: bottomPadding)) ??
          EdgeInsets.only(bottom: bottomPadding),
      child: child,
    );
  }
}

/// Extension for responsive text styles
extension ResponsiveTextStyle on TextStyle {
  TextStyle responsive(BuildContext context, {double? maxSize}) {
    final baseSize = fontSize ?? 14;
    final clamped = ResponsiveUtils.clampedFontSize(
      context,
      baseSize,
      maxSize: maxSize ?? baseSize * 1.5,
    );
    return copyWith(fontSize: clamped);
  }
}
