# DES-05 own-profile golden baselines

`own_profile_golden_test.dart` declares deterministic scenarios for:

- complete own profile;
- incomplete own profile;
- loading;
- initial error;
- edit saving state;
- saved public-profile preview.

The six declared baselines were captured and visually reviewed during the
DES-08 full redesign verification pass on 2026-07-27. The shared test flag is
`false`, so the cases run in the normal `flutter test` gate.

`own_profile_incomplete.png` covers missing media and
`own_profile_complete.png` covers the active-subscription profile state.
Validation, upload progress/error, and unsaved-change behavior remain covered
by widget/controller tests rather than duplicate snapshots. A reorder baseline
remains blocked until backend-persisted photo order exists.

To intentionally refresh the snapshots:

```powershell
flutter test --update-goldens test/features/profile/own_profile_golden_test.dart
```

Inspect every changed PNG before committing it.
