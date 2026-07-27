# DES-06 auth and onboarding golden baselines

`auth_onboarding_golden_test.dart` declares deterministic 390 x 844 scenarios
for:

- Splash/session restore;
- Welcome;
- Login default, validation, and loading;
- OTP default and invalid;
- Registration default and error;
- Basic profile;
- Preferences;
- Interests;
- Photos and upload error;
- Review/completion;
- offline bootstrap and onboarding.

The 17 baselines were captured and visually reviewed during the DES-08 full
redesign verification pass on 2026-07-27. The shared test flag is `false`, so
the cases run in the normal `flutter test` gate.

To intentionally refresh them after a reviewed UI change:

```powershell
flutter test --update-goldens test/features/auth/auth_onboarding_golden_test.dart
```

Inspect every changed PNG before committing it.
