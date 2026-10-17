import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/one_ui_card.dart';

/// واجهة اختيار لغة التطبيق بنمط One UI
class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const OneUiAppBar(
        title: AppStrings.languageTitle,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceXL,
        ),
        children: [
          OneUiCard(
            children: [
              OneUiSelectionTile(
                title: AppStrings.languageArabic,
                isSelected: true,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
