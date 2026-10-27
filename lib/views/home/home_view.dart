import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/empty_state_widget.dart';

/// الشاشة الرئيسية (لوحة التحكم العامة)
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.appIconTransparent,
              width: AppDimensions.iconLarge,
              height: AppDimensions.iconLarge,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppDimensions.spaceS),
            const Text(
              AppStrings.appNameEn,
              style: TextStyle(
                fontWeight: AppTypography.weightBold,
                fontSize: AppTypography.sizeH3,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: const Center(
        child: EmptyStateWidget(
          icon: AppIcons.dashboard,
          title: AppStrings.dashboard,
          subtitle: AppStrings.homeUnderDevelopmentMsg,
        ),
      ),
    );
  }
}
