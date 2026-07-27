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

The cases are intentionally skipped until the user-requested full redesign
verification pass. No renderer, Flutter test, analyzer, build, or emulator
command was run during DES-06. At the final pass, remove the shared skip, update
goldens with the repository's normal workflow, inspect every PNG, and commit
only reviewed baselines.
