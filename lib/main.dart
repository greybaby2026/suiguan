import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/production_provider.dart';
import 'providers/work_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/warehouse_provider.dart';
import 'services/app_update_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('=== FLUTTER ERROR ===');
      debugPrint(details.exceptionAsString());
      debugPrint(details.stack.toString());
    };

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await AppUpdateService().init();

    runApp(const SuiguanApp());
  }, (error, stack) {
    debugPrint('=== UNHANDLED ERROR ===');
    debugPrint(error.toString());
    debugPrint(stack.toString());
  });
}

class SuiguanApp extends StatelessWidget {
  const SuiguanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductionProvider()),
        ChangeNotifierProvider(create: (_) => WorkProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WarehouseProvider()),
      ],
      child: MaterialApp.router(
        title: '随管科技',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
