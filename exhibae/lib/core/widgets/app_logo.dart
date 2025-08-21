import 'package:flutter/material.dart';
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
        color: backgroundColor ?? AppTheme.white,
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTheme.white.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/exhibae-icon.png',
          height: size * 0.8,
          width: size * 0.8,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading logo: $error');
            return Icon(
              Icons.event,
              color: logoColor ?? AppTheme.gradientBlack,
              size: size * 0.5,
            );
          },
        ),
      ),
    );
  }
}
