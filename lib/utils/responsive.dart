import 'package:flutter/material.dart';

/// Responsive breakpoints for web design
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// Responsive utility class for adaptive layouts
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const Responsive({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.largeDesktop;

  /// Get responsive value based on screen size
  static double value(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop;
    } else if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, double baseSize) {
    if (isLargeDesktop(context)) {
      return baseSize * 1.2;
    } else if (isDesktop(context)) {
      return baseSize * 1.1;
    } else if (isTablet(context)) {
      return baseSize * 1.05;
    }
    return baseSize;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    if (isLargeDesktop(context)) {
      return const EdgeInsets.all(48.0);
    } else if (isDesktop(context)) {
      return const EdgeInsets.all(32.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    }
    return const EdgeInsets.all(16.0);
  }

  /// Get max width for centered content
  static double maxWidth(BuildContext context) {
    if (isLargeDesktop(context)) {
      return 1400;
    } else if (isDesktop(context)) {
      return 1200;
    } else if (isTablet(context)) {
      return 800;
    }
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (size.width >= ResponsiveBreakpoints.largeDesktop && largeDesktop != null) {
      return largeDesktop!;
    } else if (size.width >= ResponsiveBreakpoints.desktop && desktop != null) {
      return desktop!;
    } else if (size.width >= ResponsiveBreakpoints.mobile && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Extension for responsive spacing
extension ResponsiveSpacing on num {
  double get sp => this * 1.0; // Can be scaled based on screen size

  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}

/// Responsive card layout wrapper
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.maxWidth(context),
        ),
        child: Padding(
          padding: padding ?? Responsive.padding(context),
          child: child,
        ),
      ),
    );
  }
}

/// Responsive grid layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double spacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.spacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 1;

    if (Responsive.isLargeDesktop(context)) {
      crossAxisCount = 4;
    } else if (Responsive.isDesktop(context)) {
      crossAxisCount = 3;
    } else if (Responsive.isTablet(context)) {
      crossAxisCount = 2;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
