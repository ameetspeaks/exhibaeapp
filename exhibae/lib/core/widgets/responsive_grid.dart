import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool primary;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        final childAspectRatio = _getChildAspectRatio(constraints.maxWidth);
        
        return GridView.builder(
          padding: padding ?? ResponsiveUtils.getScreenPadding(context),
          physics: physics,
          shrinkWrap: shrinkWrap,
          primary: primary,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 1;      // Mobile: 1 column
    if (width < 900) return 2;      // Small tablet: 2 columns
    if (width < 1200) return 3;     // Large tablet: 3 columns
    return 4;                        // Desktop: 4 columns
  }

  double _getChildAspectRatio(double width) {
    if (width < 600) return 1.2;    // Mobile: taller cards
    if (width < 900) return 1.1;    // Small tablet: slightly taller
    if (width < 1200) return 1.0;   // Large tablet: square-ish
    return 0.9;                      // Desktop: wider cards
  }
}

class ResponsiveStaggeredGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool primary;

  const ResponsiveStaggeredGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        
        return GridView.builder(
          padding: padding ?? ResponsiveUtils.getScreenPadding(context),
          physics: physics,
          shrinkWrap: shrinkWrap,
          primary: primary,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1.0, // Fixed aspect ratio for staggered grid
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 1;      // Mobile: 1 column
    if (width < 900) return 2;      // Small tablet: 2 columns
    if (width < 1200) return 3;     // Large tablet: 3 columns
    return 4;                        // Desktop: 4 columns
  }
}
