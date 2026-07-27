import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/settings/presentation/discovery_preferences_components.dart';
import 'package:swipe_mobile_re/features/settings/presentation/settings_components.dart';
import 'package:swipe_mobile_re/shared/theme/tokens.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

// DES-08 is the full redesign verification pass, so these baselines are active.
const _baselineDeferred = false;

void main() {
  testWidgets('Settings normal golden', (tester) async {
    await _pumpGolden(
      tester,
      _settingsSurface(),
      'goldens/settings_normal.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Settings long content golden', (tester) async {
    await _pumpGolden(
      tester,
      SettingsPageScaffold(
        title: 'Settings with a deliberately long localized title',
        onBack: _noop,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 104, 20, 40),
          children: const [
            SettingsSection(
              title: 'Account and application preferences',
              children: [
                SettingsTile(
                  leadingIcon: Icons.tune_rounded,
                  title: 'Discovery preferences with a long translated heading',
                  subtitle:
                      'This subtitle wraps across several lines without '
                      'colliding with its bounded trailing status.',
                  statusLabel: 'Configured',
                ),
              ],
            ),
          ],
        ),
      ),
      'goldens/settings_long_content.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Account Settings golden', (tester) async {
    await _pumpGolden(
      tester,
      SettingsPageScaffold(
        title: 'Account',
        onBack: _noop,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 104, 20, 40),
          children: const [
            AccountInfoSection(accountId: 42),
            SizedBox(height: AppTokens.space24),
            SettingsSection(
              title: 'Danger zone',
              children: [
                SettingsTile(
                  leadingIcon: Icons.person_remove_outlined,
                  title: 'Delete account',
                  subtitle: 'Review permanent account deletion',
                  statusLabel: 'Permanent',
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
      'goldens/account_settings.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Discovery Preferences golden', (tester) async {
    final minimum = TextEditingController(text: '24');
    final maximum = TextEditingController(text: '36');
    addTearDown(minimum.dispose);
    addTearDown(maximum.dispose);
    await _pumpGolden(
      tester,
      SettingsPageScaffold(
        title: 'Discovery preferences',
        onBack: _noop,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 104, 20, 132),
          children: [
            AgeRangeControl(
              minimumController: minimum,
              maximumController: maximum,
              hasExplicitRange: true,
              onMinimumChanged: _ignoreString,
              onMaximumChanged: _ignoreString,
              onUseAutomatic: _noop,
              enabled: true,
            ),
            const SizedBox(height: AppTokens.space24),
            const SettingsSection(
              title: 'Profile preferences',
              children: [
                Padding(
                  padding: EdgeInsets.all(AppTokens.space16),
                  child: Text('Looking for · Serious relationship'),
                ),
              ],
            ),
          ],
        ),
      ),
      'goldens/discovery_preferences.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Logout confirmation golden', (tester) async {
    await _pumpGolden(
      tester,
      const Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: LogoutConfirmationSheet(),
        ),
      ),
      'goldens/logout_confirmation.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Delete confirmation golden', (tester) async {
    await _pumpGolden(
      tester,
      const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: DeleteAccountConfirmation()),
      ),
      'goldens/delete_account_confirmation.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Delete loading golden', (tester) async {
    await _pumpGolden(
      tester,
      const SettingsPageScaffold(
        title: 'Delete account',
        onBack: _noop,
        child: Center(child: DeleteAccountProgressView()),
      ),
      'goldens/delete_account_loading.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('App Information golden', (tester) async {
    await _pumpGolden(
      tester,
      SettingsPageScaffold(
        title: 'App information',
        onBack: _noop,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 104, 20, 40),
          children: const [
            SettingsSection(
              title: 'Installed application',
              children: [
                SettingsTile(
                  leadingIcon: Icons.nightlight_round,
                  title: 'Application',
                  statusLabel: 'Swipe',
                ),
                SettingsTile(
                  leadingIcon: Icons.layers_outlined,
                  title: 'Version',
                  statusLabel: '0.1.0',
                ),
                SettingsTile(
                  leadingIcon: Icons.build_outlined,
                  title: 'Build',
                  statusLabel: '1',
                ),
              ],
            ),
          ],
        ),
      ),
      'goldens/app_information.png',
    );
  }, skip: _baselineDeferred);
}

Widget _settingsSurface() => SettingsPageScaffold(
  title: 'Settings',
  onBack: _noop,
  child: ListView(
    padding: const EdgeInsets.fromLTRB(20, 104, 20, 40),
    children: const [
      SettingsSection(
        title: 'Your account',
        children: [
          SettingsTile(
            leadingIcon: Icons.person_outline_rounded,
            title: 'Account',
            subtitle: 'Account details and deletion',
          ),
          SettingsTile(
            leadingIcon: Icons.tune_rounded,
            title: 'Discovery preferences',
            subtitle: 'Age and profile preferences',
          ),
        ],
      ),
      SizedBox(height: AppTokens.space24),
      SettingsSection(
        title: 'Access',
        children: [
          SettingsTile(
            leadingIcon: Icons.workspace_premium_rounded,
            title: 'Subscription',
            subtitle: 'Premium 90 · Ends Oct 20, 2026',
            statusLabel: 'Active',
          ),
        ],
      ),
    ],
  ),
);

Future<void> _pumpGolden(WidgetTester tester, Widget child, String path) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  const key = Key('settings-golden-surface');
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: RepaintBoundary(key: key, child: child),
    ),
  );
  await tester.pump();
  await expectLater(find.byKey(key), matchesGoldenFile(path));
}

void _noop() {}
void _ignoreString(String value) {}
