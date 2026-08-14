import 'package:flutter/material.dart';

/// Breakpoints compartidos para Flutter Web / móvil.
abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 960;
  static const double desktop = 1200;
  static const double maxContentWidth = 1200;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) => widthOf(context) < mobile;

  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) => widthOf(context) >= tablet;

  static double horizontalPadding(BuildContext context) {
    final w = widthOf(context);
    if (w < mobile) return 12;
    if (w < tablet) return 16;
    return 24;
  }

  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
        horizontal: horizontalPadding(context),
        vertical: isMobile(context) ? 16 : 24,
      );
}

/// Centra el contenido y limita ancho en pantallas grandes.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
        child: Padding(
          padding: padding ?? AppBreakpoints.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}

/// Dos columnas en desktop; columna única en móvil.
class ResponsiveTwoColumn extends StatelessWidget {
  const ResponsiveTwoColumn({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = AppBreakpoints.tablet,
    this.spacing = 16,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
  });

  final Widget primary;
  final Widget secondary;
  final double breakpoint;
  final double spacing;
  final int primaryFlex;
  final int secondaryFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: primaryFlex, child: primary),
              SizedBox(width: spacing),
              Expanded(flex: secondaryFlex, child: secondary),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primary,
            SizedBox(height: spacing),
            secondary,
          ],
        );
      },
    );
  }
}
