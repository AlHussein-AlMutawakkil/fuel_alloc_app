import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// الشاشة الرئيسية (لوحة التحكم العامة)
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 64,
                color: AppColors.primaryLight.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'الرئيسية',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: 8),
              const Text(
                'سيتم تفعيل لوحة المؤشرات والأرصدة في الخطوة التالية',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
