import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/empty_state_widget.dart';

/// شاشة التقارير
class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navReports),
      ),
      body: const Center(
        child: EmptyStateWidget(
          icon: AppIcons.navReportsActive,
          title: AppStrings.reportsAndReconciliation,
          subtitle: AppStrings.reportsUnderDevelopmentMsg,
        ),
      ),
    );
  }
}
