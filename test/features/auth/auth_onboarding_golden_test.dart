import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/app/router/app_gate.dart';
import 'package:swipe_mobile_re/features/auth/presentation/app_bootstrap_screen.dart';
import 'package:swipe_mobile_re/features/auth/presentation/auth_components.dart';
import 'package:swipe_mobile_re/features/auth/presentation/phone_auth_screen.dart';
import 'package:swipe_mobile_re/features/auth/presentation/welcome_screen.dart';
import 'package:swipe_mobile_re/features/onboarding/presentation/onboarding_components.dart';
import 'package:swipe_mobile_re/features/onboarding/registration_screen.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/shared/theme/tokens.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';
import 'package:swipe_mobile_re/shared/ui/liquid_ui.dart';

// DES-08 is the full redesign verification pass, so these baselines are active.
const _baselineDeferred = false;

void main() {
  testWidgets('Splash golden', (tester) async {
    await _pumpGolden(
      tester,
      const SessionRestoreView(
        gate: AppGateState(AppGateStatus.checkingSession),
        onRetry: _noop,
      ),
      'goldens/auth_splash.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Welcome golden', (tester) async {
    await _pumpGolden(
      tester,
      const WelcomeScreen(),
      'goldens/auth_welcome.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Login default golden', (tester) async {
    await _pumpGolden(
      tester,
      const PhoneAuthScreen(),
      'goldens/auth_login_default.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Login validation golden', (tester) async {
    await _pumpGolden(
      tester,
      AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in with the phone number connected to your profile.',
        stepLabel: 'Phone',
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Phone number',
                errorText: 'Enter an 11-digit phone number starting with 7',
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            const AuthErrorBanner(
              message: 'Check the phone number and try again.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: null,
                child: const Text('Send code'),
              ),
            ),
          ],
        ),
      ),
      'goldens/auth_login_validation.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Login loading golden', (tester) async {
    await _pumpGolden(
      tester,
      AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in with the phone number connected to your profile.',
        stepLabel: 'Phone',
        child: Column(
          children: [
            const TextField(
              enabled: false,
              decoration: InputDecoration(labelText: 'Phone number'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: null,
                icon: const SizedBox.square(
                  dimension: AppTokens.iconCompact,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: const Text('Sending code'),
              ),
            ),
          ],
        ),
      ),
      'goldens/auth_login_loading.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('OTP default golden', (tester) async {
    final controller = TextEditingController(text: '123');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpGolden(
      tester,
      AuthScaffold(
        title: 'Enter your code',
        subtitle: 'We sent a six-digit code to +7 999 000 00 00.',
        stepLabel: 'Code',
        child: Column(
          children: [
            OtpInput(
              controller: controller,
              focusNode: focusNode,
              enabled: true,
              onChanged: (_) {},
              onSubmitted: (_) {},
            ),
            const Spacer(),
            const ResendCodeControl(
              secondsRemaining: 42,
              loading: false,
              onResend: null,
            ),
          ],
        ),
      ),
      'goldens/auth_otp_default.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('OTP invalid golden', (tester) async {
    final controller = TextEditingController(text: '123');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpGolden(
      tester,
      AuthScaffold(
        title: 'Enter your code',
        subtitle: 'We sent a six-digit code to +7 999 000 00 00.',
        stepLabel: 'Code',
        child: Column(
          children: [
            OtpInput(
              controller: controller,
              focusNode: focusNode,
              enabled: true,
              errorText: 'Enter the six-digit code',
              onChanged: (_) {},
              onSubmitted: (_) {},
            ),
            const SizedBox(height: AppTokens.space12),
            const AuthErrorBanner(
              message: 'The verification code is invalid or has expired.',
            ),
            const Spacer(),
            const ResendCodeControl(
              secondsRemaining: 0,
              loading: false,
              onResend: _noop,
            ),
          ],
        ),
      ),
      'goldens/auth_otp_invalid.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Registration default golden', (tester) async {
    await _pumpGolden(
      tester,
      const RegistrationScreen(phoneNumber: '79990000000'),
      'goldens/auth_registration_default.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Registration error golden', (tester) async {
    await _pumpGolden(
      tester,
      AuthScaffold(
        title: 'Create your profile',
        subtitle: 'Use the details that should appear on your profile.',
        stepLabel: '1 of 4',
        child: Column(
          children: [
            const AuthFormPanel(
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'First name',
                      errorText: 'First name is required',
                    ),
                  ),
                  SizedBox(height: AppTokens.space12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Last name',
                      errorText: 'Last name is required',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            const AuthErrorBanner(
              message: 'Check the highlighted fields and try again.',
            ),
          ],
        ),
      ),
      'goldens/auth_registration_error.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Onboarding basic profile golden', (tester) async {
    final firstNameController = TextEditingController(text: 'Mila');
    final cityController = TextEditingController(text: 'Lisbon');
    final firstNameFocusNode = FocusNode();
    final cityFocusNode = FocusNode();
    addTearDown(firstNameController.dispose);
    addTearDown(cityController.dispose);
    addTearDown(firstNameFocusNode.dispose);
    addTearDown(cityFocusNode.dispose);
    await _pumpGolden(
      tester,
      _StepSurface(
        title: 'Tell us about yourself',
        child: BasicProfileStep(
          firstNameController: firstNameController,
          cityController: cityController,
          firstNameFocusNode: firstNameFocusNode,
          cityFocusNode: cityFocusNode,
          dateOfBirth: DateTime(1994, 5, 4),
          gender: 'female',
          errors: const {},
          enabled: true,
          onFirstNameChanged: (_) {},
          onCityChanged: (_) {},
          onBirthday: _noop,
          onGenderChanged: (_) {},
        ),
      ),
      'goldens/onboarding_basic_profile.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Onboarding preferences golden', (tester) async {
    final controller = TextEditingController(
      text: 'Small galleries and long walks.',
    );
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpGolden(
      tester,
      _StepSurface(
        title: 'What brings you here?',
        child: PreferencesStep(
          aboutController: controller,
          aboutFocusNode: focusNode,
          options: const [
            ProfileAttributeOption(
              name: 'SERIOUS',
              description: 'Serious relationship',
            ),
          ],
          selectedGoal: 'Serious relationship',
          errors: const {},
          enabled: true,
          onAboutChanged: (_) {},
          onGoalChanged: (_) {},
        ),
      ),
      'goldens/onboarding_preferences.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Onboarding interests golden', (tester) async {
    await _pumpGolden(
      tester,
      const _StepSurface(
        title: 'Choose your interests',
        child: InterestsStep(
          interests: [
            ProfileInterest(id: 1, label: 'Cinema'),
            ProfileInterest(id: 2, label: 'Travel'),
            ProfileInterest(id: 3, label: 'Music'),
          ],
          selectedIds: {1, 3},
          errors: {},
          enabled: true,
          onToggle: _ignoreInt,
        ),
      ),
      'goldens/onboarding_interests.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Onboarding photos golden', (tester) async {
    await _pumpGolden(
      tester,
      _StepSurface(
        title: 'Add your best photos',
        child: ProfilePhotosStep(
          state: ProfileState(status: ProfileStatus.data, profile: _profile),
          onAdd: _noop,
          onRetryUpload: _noop,
          onDelete: _ignorePhoto,
          onSetPrimary: _ignoreInt,
        ),
      ),
      'goldens/onboarding_photos.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Onboarding photo upload error golden', (tester) async {
    await _pumpGolden(
      tester,
      _StepSurface(
        title: 'Add your best photos',
        child: ProfilePhotosStep(
          state: ProfileState(
            status: ProfileStatus.data,
            profile: _profile,
            photoError: const InvalidProfilePhotoException(
              'The selected image must be 10 MB or smaller',
            ),
            canRetryPhotoUpload: true,
          ),
          onAdd: _noop,
          onRetryUpload: _noop,
          onDelete: _ignorePhoto,
          onSetPrimary: _ignoreInt,
        ),
      ),
      'goldens/onboarding_photo_upload_error.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Onboarding review golden', (tester) async {
    await _pumpGolden(
      tester,
      _StepSurface(
        title: 'Your profile is ready',
        child: OnboardingReviewStep(profile: _profile),
      ),
      'goldens/onboarding_review.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Offline bootstrap golden', (tester) async {
    await _pumpGolden(
      tester,
      SessionRestoreView(
        gate: AppGateState(
          AppGateStatus.unavailable,
          error: Exception('offline'),
        ),
        onRetry: _noop,
      ),
      'goldens/auth_offline.png',
    );
  }, skip: _baselineDeferred);

  testWidgets('Onboarding offline error golden', (tester) async {
    await _pumpGolden(
      tester,
      const _StepSurface(
        title: 'Set up your profile',
        child: OnboardingErrorView(
          message:
              'Your profile setup is unavailable while you are offline. Your saved progress is safe.',
          onRetry: _noop,
        ),
      ),
      'goldens/onboarding_offline_error.png',
    );
  }, skip: _baselineDeferred);
}

Future<void> _pumpGolden(WidgetTester tester, Widget child, String path) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  const key = Key('auth-onboarding-golden-surface');
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.midnight(),
        home: RepaintBoundary(key: key, child: child),
      ),
    ),
  );
  await tester.pump();
  await expectLater(find.byKey(key), matchesGoldenFile(path));
}

class _StepSurface extends StatelessWidget {
  const _StepSurface({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: SingleChildScrollView(
          padding: AppTokens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppTokens.space16),
              const OnboardingProgress(step: 3, total: 5),
              const SizedBox(height: AppTokens.space20),
              Container(
                padding: const EdgeInsets.all(AppTokens.space20),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceTranslucent,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  border: Border.all(color: AppTokens.glassBorder),
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _profile = UserProfile(
  id: 1,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: DateTime(1994, 5, 4),
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Small galleries and long walks.',
  status: '',
  isSubscription: false,
  attributes: const ProfileAttributes(whatLookingFor: 'Serious relationship'),
  interests: const [
    ProfileInterest(id: 1, label: 'Cinema'),
    ProfileInterest(id: 2, label: 'Travel'),
  ],
  photos: const [],
);

void _noop() {}
void _ignoreInt(int _) {}
void _ignorePhoto(ProfilePhoto _) {}
