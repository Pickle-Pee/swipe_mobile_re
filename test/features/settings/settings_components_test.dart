import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/settings/presentation/settings_components.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('SettingsTile switch exposes real toggle semantics', (
    tester,
  ) async {
    var value = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.midnight(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: SettingsSection(
              title: 'Real controls',
              children: [
                SettingsTile(
                  leadingIcon: Icons.notifications_outlined,
                  title: 'Supported switch',
                  subtitle: 'A test-only real state holder',
                  switchValue: value,
                  onSwitchChanged: (next) => setState(() => value = next),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(SettingsTile)),
      matchesSemantics(
        label: 'Supported switch, A test-only real state holder',
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(value, isFalse);
  });

  testWidgets('destructive tile announces consequence without color alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.midnight(),
        home: Scaffold(
          body: SettingsSection(
            title: 'Session',
            children: [
              SettingsTile(
                leadingIcon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'Remove private data from this device',
                destructive: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(SettingsTile)).label,
      contains('Destructive action'),
    );
  });
}
