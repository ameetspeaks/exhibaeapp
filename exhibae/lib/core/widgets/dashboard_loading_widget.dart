import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

class DashboardLoadingWidget extends StatelessWidget {
  final String message;
  
  const DashboardLoadingWidget({
    super.key,
    this.message = 'Loading dashboard...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundPeach,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: ResponsiveUtils.getIconSize(context, mobile: 40, tablet: 50, desktop: 60),
              height: ResponsiveUtils.getIconSize(context, mobile: 40, tablet: 50, desktop: 60),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            Text(
              message,
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const DashboardErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundPeach,
      child: Center(
        child: Padding(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveUtils.getIconSize(context, mobile: 48, tablet: 56, desktop: 64),
                color: AppTheme.errorRed,
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                  color: AppTheme.primaryMaroon,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              Text(
                message,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                  color: AppTheme.primaryMaroon.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 24, desktop: 28),
                      vertical: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardEmptyWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const DashboardEmptyWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveUtils.getScreenPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: ResponsiveUtils.getIconSize(context, mobile: 48, tablet: 56, desktop: 64),
              color: AppTheme.primaryMaroon.withOpacity(0.6),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                color: AppTheme.primaryMaroon,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            Text(
              message,
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                color: AppTheme.primaryMaroon.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 24, desktop: 28),
                    vertical: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
