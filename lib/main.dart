import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/accounts_controller.dart';
import 'controllers/stations_controller.dart';
import 'controllers/transactions_controller.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'views/main_layout_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FuelAllocApp());
}

class FuelAllocApp extends StatelessWidget {
  const FuelAllocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsController()),
        ChangeNotifierProvider(create: (_) => StationsController()),
        ChangeNotifierProvider(create: (_) => TransactionsController()),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          // ضمان اتجاه النص والواجهات من اليمين لليسار (RTL) للغة العربية
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox(),
          );
        },
        home: const MainLayoutView(),
      ),
    );
  }
}
