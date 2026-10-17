import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/empty_state_widget.dart';

/// الشاشة الرئيسية (لوحة التحكم العامة)
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(AppStrings.navHome),
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
