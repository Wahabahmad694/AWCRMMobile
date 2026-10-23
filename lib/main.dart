import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/generateRoutes.dart';
import 'di_container.dart';
import 'repositories/auth_repository.dart';
import 'utils/themeProvider.dart';
import 'services/secure_storage_service.dart';
import 'view/startup/startup_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDi();
  runApp(const AwCrmApp());
}

class AwCrmApp extends StatefulWidget {
  const AwCrmApp({super.key});

  @override
  State<AwCrmApp> createState() => _AwCrmAppState();
}

class _AwCrmAppState extends State<AwCrmApp> {
  late final startup = AppStartup(
    sl<AuthRepository>(),
    sl<SecureStorageService>(),
  );
  late final router = RouteGenerator.createRouter(
    sl<AuthRepository>(),
    startup: startup,
  );

  @override
  void initState() {
    super.initState();
    startup.start();
  }

  @override
  void dispose() {
    router.dispose();
    startup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = sl<ThemeProvider>();

    return ChangeNotifierProvider.value(
      value: themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, tp, _) {
          return MaterialApp.router(
            title: 'AWC',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme(),
            darkTheme: ThemeProvider.darkTheme(),
            themeMode: tp.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
