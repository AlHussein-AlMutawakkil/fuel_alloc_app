import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_strings.dart';
import '../core/widgets/operation_entry_sheet.dart';
import 'accounts/accounts_view.dart';
import 'home/home_view.dart';
import 'reports/reports_view.dart';
import 'settings/settings_view.dart';

/// الإطار العام للتطبيق: شريط التنقل السفلي المكون من 4 تبويبات (بدون قائمة جانبية)
class MainLayoutView extends StatefulWidget {
  const MainLayoutView({super.key});

  @override
  State<MainLayoutView> createState() => _MainLayoutViewState();
}

class _MainLayoutViewState extends State<MainLayoutView> {
  int _currentIndex = 1; // نبدأ بتبويب الحسابات

  final List<Widget> _screens = const [
    HomeView(),
    AccountsView(),
    ReportsView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex != 3
          ? FloatingActionButton(
              backgroundColor: AppColors.supplyGreen,
              foregroundColor: AppColors.textWhite,
              tooltip: AppStrings.registerOperation,
              child: const Icon(
                AppIcons.add,
                size: AppDimensions.iconExtraLarge,
              ),
              onPressed: () {
                OperationEntrySheet.show(context: context);
              },
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: AppDimensions.borderWidthThin,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(AppIcons.navHome),
              activeIcon: Icon(AppIcons.navHomeActive),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(AppIcons.navAccounts),
              activeIcon: Icon(AppIcons.navAccountsActive),
              label: AppStrings.navAccounts,
            ),
            BottomNavigationBarItem(
              icon: Icon(AppIcons.navReports),
              activeIcon: Icon(AppIcons.navReportsActive),
              label: AppStrings.navReports,
            ),
            BottomNavigationBarItem(
              icon: Icon(AppIcons.navSettings),
              activeIcon: Icon(AppIcons.navSettingsActive),
              label: AppStrings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
