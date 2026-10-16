import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex != 3
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              tooltip: 'تسجيل قيد',
              child: const Icon(Icons.add, size: 28),
              onPressed: () {
                OperationEntrySheet.show(context: context);
              },
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: AppStrings.navAccounts,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined),
              activeIcon: Icon(Icons.insert_chart),
              label: AppStrings.navReports,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: AppStrings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
