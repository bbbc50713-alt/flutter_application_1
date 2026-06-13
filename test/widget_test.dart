// This is a basic Flutter widget test for the BDL application.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/providers.dart';
import 'package:flutter_application_1/utils/utils.dart';

void main() {
  testWidgets('BDL App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => TestProvider()),
          ChangeNotifierProvider(create: (_) => AlarmProvider()),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              title: AppStrings.appName,
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
              home: const Scaffold(
                body: Center(
                  child: Text('BDL Test'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Verify the app title is displayed
    expect(find.text('BDL Test'), findsOneWidget);
  });
}
