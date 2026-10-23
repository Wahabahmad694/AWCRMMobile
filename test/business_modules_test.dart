import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aw_crm/config/generateRoutes.dart';
import 'package:aw_crm/data/remote/api_service.dart';
import 'package:aw_crm/di_container.dart';
import 'package:aw_crm/models/response/auth_response.dart';
import 'package:aw_crm/repositories/auth_repository.dart';
import 'package:aw_crm/repositories/business_repository.dart';
import 'package:aw_crm/services/secure_storage_service.dart';
import 'package:aw_crm/utils/themeProvider.dart';
import 'package:aw_crm/view/startup/startup_view.dart';
import 'package:aw_crm/view/tabs/business/business_module.dart';
import 'package:aw_crm/view/tabs/business/business_view.dart';
import 'package:aw_crm/view/tabs/business/business_editor.dart';
import 'package:aw_crm/view/widget/app_drawer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? body,
    Future<void>? cancel,
  ) async => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(dynamic data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_AWC')) {
      final loader = FontLoader('Arial')
        ..addFont(
          File('/System/Library/Fonts/Supplemental/Arial.ttf')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b)),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  late ApiService api;
  late AuthRepository auth;
  late SecureStorageService storage;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await sl.reset();
    storage = SecureStorageService();
    api = ApiService(
      storageService: storage,
      baseUrl: 'https://example.test/api/v1',
    );
    auth = AuthRepository(apiService: api, storageService: storage);
    sl.registerSingleton<ApiService>(api);
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<SecureStorageService>(storage);
    auth.currentUser = const UserProfile(
      id: 'user',
      name: 'Test User',
      email: 'test@example.test',
    );
    api.dio.httpClientAdapter = FakeAdapter(
      (_) => response({'items': [], 'has_more': false}),
    );
  });
  tearDown(() async {
    await sl.reset();
  });

  test(
    'list decoding rejects invalid responses and accepts supported envelopes',
    () {
      expect(
        BusinessRepository.rows({
          'accounts': [
            {'id': 'cash'},
          ],
        }).single['id'],
        'cash',
      );
      expect(
        () => BusinessRepository.rows({'unexpected': true}),
        throwsA(isA<BusinessFailure>()),
      );
    },
  );

  test(
    'login caches user, memberships, organization and both tokens',
    () async {
      api.dio.httpClientAdapter = FakeAdapter(
        (_) => response({
          'access_token': 'access-token-value',
          'refresh_token': 'refresh-token-value-long-enough',
          'user': {
            'id': 'user-1',
            'name': 'Ayesha',
            'email': 'ayesha@example.test',
          },
          'memberships': [
            {
              'organization_id': 'org-1',
              'name': 'Ayesha Traders',
              'permissions': ['orders.read'],
              'role': 'owner',
            },
          ],
        }),
      );
      final result = await auth.login(
        identifier: 'ayesha@example.test',
        password: 'secret',
      );
      expect(result.isSuccess, isTrue);
      expect(await storage.getAccessToken(), 'access-token-value');
      expect(
        await storage.getRefreshToken(),
        'refresh-token-value-long-enough',
      );
      expect((await storage.getCachedUser())?['name'], 'Ayesha');
      expect(
        (await storage.getCachedMemberships()).single['organization_id'],
        'org-1',
      );
      expect(await storage.getOrganizationId(), 'org-1');
    },
  );

  test(
    'startup rotates an expired access token and caches the current profile',
    () async {
      final paths = <String>[];
      await storage.saveTokens(
        accessToken: 'expired-access',
        refreshToken: 'refresh-token-value-long-enough',
      );
      api.dio.httpClientAdapter = FakeAdapter((request) {
        paths.add(request.path);
        if (request.path.endsWith('/auth/me') &&
            request.headers['Authorization'] == 'Bearer expired-access') {
          return response({
            'error': {'code': 'unauthorized', 'message': 'Expired'},
          }, 401);
        }
        if (request.path.endsWith('/auth/refresh')) {
          return response({
            'access_token': 'rotated-access',
            'refresh_token': 'rotated-refresh-token-long-enough',
          });
        }
        if (request.path.endsWith('/auth/me')) {
          return response({
            'user': {
              'id': 'user-2',
              'name': 'Bilal',
              'email': 'bilal@example.test',
            },
          });
        }
        if (request.path.endsWith('/organizations')) {
          return response({
            'items': [
              {
                'organization_id': 'org-2',
                'name': 'Bilal Store',
                'permissions': ['customers.read'],
              },
            ],
          });
        }
        return response({});
      });
      expect(await auth.restoreSession(), isTrue);
      expect(paths, contains('/auth/refresh'));
      expect(await storage.getAccessToken(), 'rotated-access');
      expect(
        await storage.getRefreshToken(),
        'rotated-refresh-token-long-enough',
      );
      expect((await storage.getCachedUser())?['name'], 'Bilal');
      expect(await storage.getOrganizationId(), 'org-2');
      expect(auth.currentUser?.email, 'bilal@example.test');
    },
  );

  testWidgets(
    'first launch runs splash, onboarding and then login; onboarding persists',
    (tester) async {
      auth.currentUser = null;
      final startup = AppStartup(auth, storage);
      final router = RouteGenerator.createRouter(auth, startup: startup);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeProvider.lightTheme(),
          routerConfig: router,
        ),
      );
      startup.start();
      await tester.pump();
      expect(find.byType(SplashView), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingView), findsOneWidget);
      await tester.ensureVisible(find.text('Get started'));
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(await storage.getOnboardingSeen(), isTrue);
      await storage.clearAll();
      expect(await storage.getOnboardingSeen(), isTrue);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      startup.dispose();
    },
  );

  testWidgets('every missing module is routed in the active app', (
    tester,
  ) async {
    auth.isPreviewMode = true;
    final router = RouteGenerator.createRouter(auth);
    router.go('/leads');
    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeProvider.lightTheme(),
        routerConfig: router,
      ),
    );
    for (final module in BusinessModule.values) {
      router.go(module.route);
      await tester.pumpAndSettle();
      expect(find.byType(BusinessView), findsOneWidget);
      expect(
        find.text('Explore ${module.title.toLowerCase()}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    router.go('/imports');
    await tester.pumpAndSettle();
    expect(find.text('Imports are not available yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });

  testWidgets('lead search resets page and uses documented query fields', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    api.dio.httpClientAdapter = FakeAdapter((o) {
      requests.add(o);
      return response({
        'items': [
          {'id': 'lead', 'name': 'Ali Traders', 'expected_value_paisa': 125050},
        ],
        'has_more': false,
      });
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeProvider.lightTheme(),
        home: const BusinessView(module: BusinessModule.leads),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ali Traders'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ali');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(requests.last.path, '/leads');
    expect(requests.last.queryParameters, {
      'page': 1,
      'limit': 20,
      'search': 'Ali',
    });
  });

  testWidgets(
    'lead form sends exact paisa and preserves idempotency key on retry',
    (tester) async {
      final requests = <RequestOptions>[];
      api.dio.httpClientAdapter = FakeAdapter((o) {
        requests.add(o);
        return response({
          'error': {'message': 'Please retry'},
        }, 503);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme(),
          home: const BusinessEditor(module: BusinessModule.leads),
        ),
      );
      final name = find.widgetWithText(TextFormField, 'Name *');
      await tester.enterText(name, 'Ali');
      final money = find.widgetWithText(TextFormField, 'Expected value');
      await tester.ensureVisible(money);
      await tester.enterText(money, '1250.50');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(requests.length, 1);
      expect(requests.single.data['expected_value_paisa'], 125050);
      expect(requests.single.data['name'], 'Ali');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(requests.length, 2);
      expect(
        requests[0].headers['Idempotency-Key'],
        requests[1].headers['Idempotency-Key'],
      );
      expect(find.text('Please retry'), findsOneWidget);
    },
  );

  testWidgets(
    'cash balances do not receive unsupported list query parameters',
    (tester) async {
      final requests = <RequestOptions>[];
      api.dio.httpClientAdapter = FakeAdapter((o) {
        requests.add(o);
        return response([
          {
            'id': 'cash',
            'name': 'Cash drawer',
            'type': 'cash',
            'balance_paisa': 12300,
          },
        ]);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme(),
          home: const BusinessView(module: BusinessModule.cashBank),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests.single.path, '/payment-accounts/balances');
      expect(requests.single.queryParameters, isEmpty);
      expect(find.text('Cash drawer'), findsOneWidget);
    },
  );

  testWidgets(
    'return completion submits the current version and selected resolution',
    (tester) async {
      final requests = <RequestOptions>[];
      api.dio.httpClientAdapter = FakeAdapter((o) {
        requests.add(o);
        return response({
          'error': {'message': 'Temporary failure'},
        }, 503);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeProvider.lightTheme(),
          home: const BusinessEditor(
            module: BusinessModule.returns,
            action: 'complete',
            initial: {
              'id': 'return-1',
              'version': 4,
              'resolution': 'credit_note',
            },
          ),
        ),
      );
      await tester.tap(find.text('Confirm complete'));
      await tester.pumpAndSettle();
      expect(requests.single.path, '/returns/return-1/complete');
      expect(requests.single.data, {'expected_version': 4, 'auto_apply': true});
      expect(requests.single.headers['Idempotency-Key'], isNotEmpty);
    },
  );

  testWidgets('credit application rejects amounts above remaining credit', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    api.dio.httpClientAdapter = FakeAdapter((o) {
      requests.add(o);
      return response({});
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeProvider.lightTheme(),
        home: const BusinessEditor(
          module: BusinessModule.creditNotes,
          action: 'apply',
          initial: {
            'id': 'credit-1',
            'order_id': 'order-1',
            'remaining_paisa': 1000,
          },
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Credit amount *'),
      '10.01',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm apply'));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    expect(
      find.text('Enter an amount within the available credit.'),
      findsOneWidget,
    );
  });

  testWidgets('mobile screens and new drawer entries fit at 390 pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final captureKey = GlobalKey();
    Future<void> show(Widget screen, String name) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme(),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      if (screen is! SplashView) await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_AWC')) {
        await tester.runAsync(() async {
          final image =
              await (captureKey.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/awc-$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }

    await show(const SplashView(), 'splash');
    await show(OnboardingView(onContinue: () async {}), 'onboarding');
    await show(const BusinessView(module: BusinessModule.leads), 'leads');
    await show(
      const BusinessEditor(module: BusinessModule.quotations),
      'quotation-form',
    );
    await show(
      const BusinessView(module: BusinessModule.cashBank),
      'cash-bank',
    );
    await show(const Scaffold(body: AppDrawer(currentRoute: '/leads')), 'menu');
    expect(find.text('Leads'), findsOneWidget);
    expect(find.text('Quotations'), findsOneWidget);
    expect(find.text('Returns'), findsOneWidget);
  });
}
