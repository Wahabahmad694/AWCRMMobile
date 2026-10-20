import 'package:aw_crm/app/theme/app_theme.dart';
import 'package:aw_crm/core/api/api_client.dart';
import 'package:aw_crm/core/auth/session.dart';
import 'package:aw_crm/features/dashboard/presentation/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview entry does not authenticate or attach a token', () {
    final api = ApiClient('http://localhost:3000/api');
    final session = Session(api);
    session.enterPreview();
    expect(session.previewMode, isTrue);
    expect(session.signedIn, isFalse);
    expect(api.accessToken, isNull);
    session.dispose();
  });

  testWidgets('dashboard never presents fabricated metrics', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme(Brightness.light),
      home: const Scaffold(body: DashboardContent())));
    expect(find.text('Business overview'), findsOneWidget);
    expect(find.text('No live data'), findsNWidgets(4));
  });
}
