import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BrandCard extends StatelessWidget {
  final Map<String, dynamic> brand;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const BrandCard({
    super.key,
    required this.brand,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isFavorited = brand['is_favorited'] ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLightGray),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Brand logo/avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryWarm,
                  ),
                  child: brand['avatar_url'] != null
                      ? Image.network(
                          brand['avatar_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.secondaryWarm,
                              child: Icon(
                                Icons.store,
                                size: 32,
                                color: AppTheme.primaryMaroon,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.secondaryWarm,
                          child: Icon(
                            Icons.store,
                            size: 32,
                            color: AppTheme.primaryMaroon,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Brand name
              Expanded(
                child: Text(
                  brand['company_name'] ?? 'Brand Name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Favorite icon
              IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? AppTheme.errorRed : AppTheme.textMediumGray,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
