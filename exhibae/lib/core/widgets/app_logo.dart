import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? logoColor;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 80,
    this.backgroundColor,
    this.logoColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTheme.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.2),
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          fit: BoxFit.contain,
          colorFilter: logoColor != null
              ? ColorFilter.mode(logoColor!, BlendMode.srcIn)
              : null,
        ),
      ),
    );
  }
}
