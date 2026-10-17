import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/one_ui_card.dart';

enum AppThemeMode { system, light, dark }

/// واجهة سمة الألوان (المظهر) بنمط One UI
class ThemeSettingsView extends StatefulWidget {
  const ThemeSettingsView({super.key});

  @override
  State<ThemeSettingsView> createState() => _ThemeSettingsViewState();
}

class _ThemeSettingsViewState extends State<ThemeSettingsView> {
  AppThemeMode _selectedTheme = AppThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const OneUiAppBar(
        title: AppStrings.themeTitle,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceXL,
        ),
        children: [
          OneUiCard(
            children: [
              OneUiSelectionTile(
                title: AppStrings.themeSystem,
                isSelected: _selectedTheme == AppThemeMode.system,
                onTap: () {
                  setState(() => _selectedTheme = AppThemeMode.system);
                },
              ),
              OneUiSelectionTile(
                title: AppStrings.themeLight,
                isSelected: _selectedTheme == AppThemeMode.light,
                onTap: () {
                  setState(() => _selectedTheme = AppThemeMode.light);
                },
              ),
              OneUiSelectionTile(
                title: AppStrings.themeDark,
                isSelected: _selectedTheme == AppThemeMode.dark,
                onTap: () {
                  setState(() => _selectedTheme = AppThemeMode.dark);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
