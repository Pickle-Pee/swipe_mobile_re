import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/auth/presentation/welcome_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('Welcome exposes registration and login without fake claims', (
    tester,
  ) async {
    await _pumpWelcome(tester);

    expect(find.text('Meet people\nat your pace.'), findsOneWidget);
    expect(find.byKey(const Key('welcome-register')), findsOneWidget);
    expect(find.byKey(const Key('welcome-login')), findsOneWidget);
    expect(find.textContaining('AI-powered'), findsNothing);
    expect(find.textContaining('users'), findsNothing);
  });

  testWidgets(
    'Welcome remains scrollable at 1.3 text scale on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.midnight(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const WelcomeScreen(),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpWelcome(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(theme: AppTheme.midnight(), home: const WelcomeScreen()),
  );
}
