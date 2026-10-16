import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/one_ui_card.dart';

/// واجهة اختيار لغة التطبيق بنمط One UI
class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text('اللغة'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
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
