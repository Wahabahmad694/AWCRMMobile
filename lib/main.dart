import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/generateRoutes.dart';
import 'di_container.dart';
import 'repositories/auth_repository.dart';
import 'utils/themeProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDi();
  await sl<AuthRepository>().restoreSession();
  runApp(const AwCrmApp());
}

class AwCrmApp extends StatefulWidget {
  const AwCrmApp({super.key});

  @override
  State<AwCrmApp> createState() => _AwCrmAppState();
}

class _AwCrmAppState extends State<AwCrmApp> {
  late final router = RouteGenerator.createRouter(sl<AuthRepository>());

  @override
  Widget build(BuildContext context) {
    final themeProvider = sl<ThemeProvider>();

    return ChangeNotifierProvider.value(
      value: themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, tp, _) {
          return MaterialApp.router(
            title: 'AW CRM',
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
