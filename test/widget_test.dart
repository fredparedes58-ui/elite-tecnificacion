// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myapp/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{}; // Starting with an empty map
          }
          if (methodCall.method.startsWith('set')) {
            return true;
          }
          return null;
        });

    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'example-key',
    );
  });

  testWidgets('Dashboard title smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.binding.runAsync(() async {
      await tester.pumpWidget(
        const SizedBox(width: 600, height: 800, child: MyApp()),
      );
      await tester.pumpAndSettle();
    });

    // Verify that the login screen is shown.
    expect(find.text('Entrar'), findsOneWidget);
  });
}
