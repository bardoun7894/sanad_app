import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/glass_card.dart';

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final isMobile = AdminResponsive.isMobile(context);

    return SingleChildScrollView(
      padding: AdminResponsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.adminDataManagement,
            style: AppTypography.headingLarge.copyWith(
              color: textColor,
              fontSize: isMobile ? 24 : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.adminManageAppData,
            style: AppTypography.bodyMedium.copyWith(
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          GlassCard(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storage_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.adminFirestoreData,
                            style: AppTypography.headingSmall.copyWith(
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.adminManageViaCMS,
                            style: AppTypography.bodySmall.copyWith(
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.adminUseCMSScreens,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(AppStrings.adminQuotesViaCMS, textColor),
                  _buildBulletPoint(AppStrings.adminContentViaCMS, textColor),
                  _buildBulletPoint(AppStrings.adminChallengesViaCMS, textColor),
                  _buildBulletPoint(AppStrings.adminUsersViaManagement, textColor),
                  _buildBulletPoint(AppStrings.adminTherapistsViaManagement, textColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}
