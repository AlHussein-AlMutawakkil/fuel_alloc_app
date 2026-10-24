import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/accounts_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/backup_controller.dart';
import 'controllers/messaging_controller.dart';
import 'controllers/stations_controller.dart';
import 'controllers/transactions_controller.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'services/backup_background_service.dart';
import 'views/main_layout_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackupBackgroundService.initialize();
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
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => BackupController()),
        ChangeNotifierProvider(create: (_) => MessagingController()),
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
