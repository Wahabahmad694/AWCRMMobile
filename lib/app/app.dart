import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api/api_client.dart';
import '../core/auth/session.dart';
import '../features/authentication/presentation/login_page.dart';
import '../features/dashboard/presentation/workspace.dart';
import 'theme/app_theme.dart';

class CrmApp extends StatefulWidget {
  const CrmApp({super.key});
  @override
  State<CrmApp> createState() => _CrmAppState();
}

class _CrmAppState extends State<CrmApp> {
  late final Session session;
  late final GoRouter router;
  ThemeMode themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://aw-crm-mu.vercel.app/api/v1');
    final api = ApiClient(baseUrl);
    GetIt.I.registerSingleton<ApiClient>(api);
    session = Session(api);
    router = GoRouter(
      refreshListenable: session,
      initialLocation: '/dashboard',
      redirect: (_, state) {
        if (session.restoring) return state.matchedLocation == '/loading' ? null : '/loading';
        if (!session.signedIn && !session.previewMode) return state.matchedLocation == '/login' ? null : '/login';
        if (state.matchedLocation == '/login' || state.matchedLocation == '/loading') return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/loading', builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(path: '/dashboard', builder: (_, _) => const WorkspacePage(section: WorkspaceSection.dashboard)),
        GoRoute(path: '/assistant', builder: (_, _) => const WorkspacePage(section: WorkspaceSection.assistant)),
        GoRoute(path: '/customers', builder: (_, _) => const WorkspacePage(section: WorkspaceSection.customers)),
        GoRoute(path: '/orders', builder: (_, _) => const WorkspacePage(section: WorkspaceSection.orders)),
        GoRoute(path: '/payments', builder: (_, _) => const WorkspacePage(section: WorkspaceSection.payments)),
        GoRoute(path: '/account', builder: (_, _) => const WorkspacePage(section: WorkspaceSection.account)),
      ],
    );
    session.restore();
  }

  @override
  void dispose() {
    router.dispose();
    session.dispose();
    GetIt.I.unregister<ApiClient>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: session,
    child: MaterialApp.router(
      title: 'AW CRM',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    ),
  );
}
