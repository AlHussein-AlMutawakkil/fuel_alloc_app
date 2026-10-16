import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/app_text_styles.dart';
import '../core/widgets/operation_entry_sheet.dart';
import 'accounts/accounts_view.dart';
import 'data/fuel_types_view.dart';
import 'data/stations_view.dart';
import 'data/units_view.dart';
import 'home/home_view.dart';
import 'reports/reports_view.dart';

/// الإطار العام للتطبيق: شريط التنقل السفلي والقائمة الجانبية
class MainLayoutView extends StatefulWidget {
  const MainLayoutView({super.key});

  @override
  State<MainLayoutView> createState() => _MainLayoutViewState();
}

class _MainLayoutViewState extends State<MainLayoutView> {
  int _currentIndex = 1; // نبدأ بتبويب الحسابات مباشرة حسب طلب المستخدم

  final List<Widget> _screens = const [
    HomeView(),
    AccountsView(),
    ReportsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildAppDrawer(context),
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF15803D),
        foregroundColor: Colors.white,
        tooltip: 'تسجيل قيد',
        child: const Icon(Icons.add, size: 28),
        onPressed: () {
          OperationEntrySheet.show(context: context);
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
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
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // رأس القائمة الجانبية باللون الكحلي الرسمي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_gas_station, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.appTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة ومحاسبة مخصصات الوقود',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // قسم البيانات والقوائم المرجعية
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // بند البيانات الرئيسي
                ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.folder_outlined, color: AppColors.primary),
                  title: const Text(
                    AppStrings.drawerData,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  children: [
                    // 1. الوحدات
                    ListTile(
                      contentPadding: const EdgeInsets.only(right: 36, left: 16),
                      leading: const Icon(Icons.straighten, size: 20, color: AppColors.textSecondary),
                      title: const Text(AppStrings.dataUnits, style: AppTextStyles.body),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UnitsView()),
                        );
                      },
                    ),

                    // 2. المحطات
                    ListTile(
                      contentPadding: const EdgeInsets.only(right: 36, left: 16),
                      leading: const Icon(Icons.local_gas_station_outlined, size: 20, color: AppColors.textSecondary),
                      title: const Text(AppStrings.dataStations, style: AppTextStyles.body),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StationsView()),
                        );
                      },
                    ),

                    // 3. الأصناف
                    ListTile(
                      contentPadding: const EdgeInsets.only(right: 36, left: 16),
                      leading: const Icon(Icons.category_outlined, size: 20, color: AppColors.textSecondary),
                      title: const Text(AppStrings.dataFuelTypes, style: AppTextStyles.body),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FuelTypesView()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // أسفل القائمة
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'الإصدار 1.0.0 (رسمي)',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
