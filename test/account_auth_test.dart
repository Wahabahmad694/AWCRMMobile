import 'package:aw_crm/app/theme/app_theme.dart';
import 'package:aw_crm/core/api/api_client.dart';
import 'package:aw_crm/core/auth/session.dart';
import 'package:aw_crm/core/design_system/error_banner.dart';
import 'package:aw_crm/features/account/presentation/account_page.dart';
import 'package:aw_crm/features/authentication/presentation/login_page.dart';
import 'package:aw_crm/features/dashboard/presentation/workspace.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Sign In & Account Endpoints', () {
    test('POST /auth/register parses response and establishes session', () async {
      final api = ApiClient('https://example.com/api/v1');
      api.dio.httpClientAdapter = _FakeAdapter((options) async {
        if (options.path.endsWith('/auth/register')) {
          return ResponseBody.fromString(
            '{"access_token": "acc_123", "refresh_token": "ref_123"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        if (options.path.endsWith('/auth/me')) {
          return ResponseBody.fromString(
            '{"user": {"id": "u1", "name": "Ali", "email": "ali@test.com"}, "memberships": [{"organization_id": "org_1", "role": "owner", "permissions": ["all"], "organization": {"id": "org_1", "name": "Ali Traders", "subscription_status": "active"}}]}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      });

      final session = Session(api);
      final registered = await session.register(
        name: 'Ali',
        email: 'ali@test.com',
        password: 'password123',
        organizationName: 'Ali Traders',
      );

      expect(registered, isTrue);
      expect(session.signedIn, isTrue);
      expect(session.user?.name, 'Ali');
      expect(session.user?.email, 'ali@test.com');
      expect(session.organizationId, 'org_1');
      expect(session.readOnly, isFalse);

      session.dispose();
    });

    test('POST /auth/password/forgot sends request and returns server message', () async {
      final api = ApiClient('https://example.com/api/v1');
      api.dio.httpClientAdapter = _FakeAdapter((options) async {
        if (options.path.endsWith('/auth/password/forgot')) {
          return ResponseBody.fromString(
            '{"message": "Reset instructions sent to your email."}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      });

      final session = Session(api);
      final msg = await session.forgotPassword('demo@awcrm.test');
      expect(msg, 'Reset instructions sent to your email.');

      session.dispose();
    });

    test('POST /auth/password/reset resets password successfully', () async {
      final api = ApiClient('https://example.com/api/v1');
      api.dio.httpClientAdapter = _FakeAdapter((options) async {
        if (options.path.endsWith('/auth/password/reset')) {
          return ResponseBody.fromString(
            '{"message": "Password successfully updated."}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      });

      final session = Session(api);
      final msg = await session.resetPassword(
        token: 'token-abc',
        newPassword: 'new-secure-password',
      );
      expect(msg, 'Password successfully updated.');

      session.dispose();
    });

    test('POST /auth/password/change changes user password', () async {
      final api = ApiClient('https://example.com/api/v1');
      api.dio.httpClientAdapter = _FakeAdapter((options) async {
        if (options.path.endsWith('/auth/password/change')) {
          return ResponseBody.fromString(
            '{"message": "Your password has been changed."}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      });

      final session = Session(api);
      final msg = await session.changePassword(
        currentPassword: 'old-pass',
        newPassword: 'new-pass',
      );
      expect(msg, 'Your password has been changed.');

      session.dispose();
    });

    test('GET /auth/sessions and DELETE /auth/sessions/:id handles active devices', () async {
      final api = ApiClient('https://example.com/api/v1');
      String? deletedId;
      api.dio.httpClientAdapter = _FakeAdapter((options) async {
        if (options.path.endsWith('/auth/sessions') && options.method == 'GET') {
          return ResponseBody.fromString(
            '{"sessions": [{"id": "s_1", "user_agent": "Chrome / Mac", "ip_address": "127.0.0.1", "is_current": true}, {"id": "s_2", "user_agent": "Flutter / Android", "ip_address": "10.0.2.2", "is_current": false}]}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        if (options.path.contains('/auth/sessions/') && options.method == 'DELETE') {
          deletedId = options.path.split('/').last;
          return ResponseBody.fromString('{"message": "Session revoked"}', 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType]
          });
        }
        return ResponseBody.fromString('{}', 404);
      });

      final session = Session(api);
      final sessions = await session.getSessions();
      expect(sessions.length, 2);
      expect(sessions[0].id, 's_1');
      expect(sessions[0].userAgent, 'Chrome / Mac');
      expect(sessions[0].isCurrent, isTrue);
      expect(sessions[1].id, 's_2');
      expect(sessions[1].isCurrent, isFalse);

      await session.revokeSession('s_2');
      expect(deletedId, 's_2');

      session.dispose();
    });

    test('Subscription suspension turns on readOnly mode', () async {
      final api = ApiClient('https://example.com/api/v1');
      api.dio.httpClientAdapter = _FakeAdapter((options) async {
        if (options.path.endsWith('/auth/me')) {
          return ResponseBody.fromString(
            '{"user": {"id": "u1", "name": "Owner"}, "memberships": [{"organization_id": "org_suspended", "role": "owner", "permissions": ["all"], "organization": {"id": "org_suspended", "name": "Suspended Org", "subscription_status": "suspended"}}]}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      });

      final session = Session(api);
      await session.loadProfile();

      expect(session.signedIn, isTrue);
      expect(session.readOnly, isTrue);

      session.dispose();
    });
  });

  group('UI & Presentation', () {
    testWidgets('ApiErrorBanner displays message, validation details and request ID', (tester) async {
      const failure = ApiFailure(
        'Submission failed',
        code: 'invalid_request',
        requestId: 'req-98765',
        details: {
          'fields': [
            {'field': 'email', 'message': 'Email is already taken'}
          ]
        },
      );

      await tester.pumpWidget(MaterialApp(
        theme: appTheme(Brightness.light),
        home: const Scaffold(
          body: ApiErrorBanner(error: failure),
        ),
      ));

      expect(find.text('Submission failed'), findsOneWidget);
      expect(find.text('• email: Email is already taken'), findsOneWidget);
      expect(find.text('Request ID: req-98765'), findsOneWidget);
    });

    testWidgets('LoginPage switches views between Sign in, Register, Forgot Password', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = ApiClient('https://example.com/api/v1');
      final session = Session(api);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: MaterialApp(
            theme: appTheme(Brightness.light),
            home: const LoginPage(),
          ),
        ),
      );

      // Initially on Sign in view
      expect(find.text('Welcome to AW CRM'), findsOneWidget);
      expect(find.text('Email or phone'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      // Tap Register
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Organization name'), findsOneWidget);

      // Switch back to Sign in
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to AW CRM'), findsOneWidget);

      // Tap Forgot password
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Send reset code'), findsOneWidget);

      session.dispose();
    });

    testWidgets('WorkspacePage renders subscription banner when readOnly is true', (tester) async {
      final api = ApiClient('https://example.com/api/v1');
      final session = Session(api);
      session.readOnly = true;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: MaterialApp(
            theme: appTheme(Brightness.light),
            home: const WorkspacePage(section: WorkspaceSection.dashboard),
          ),
        ),
      );

      expect(
        find.text('Your subscription is read-only. Contact your organization owner.'),
        findsOneWidget,
      );

      session.dispose();
    });

    testWidgets('AccountPage renders in preview mode without error', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = ApiClient('https://example.com/api/v1');
      final session = Session(api);
      session.enterPreview();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: MaterialApp(
            theme: appTheme(Brightness.light),
            home: const Scaffold(
              body: AccountPage(),
            ),
          ),
        ),
      );

      expect(find.text('Account & Organization'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Active Sessions'), findsOneWidget);

      session.dispose();
    });
  });
}
