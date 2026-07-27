# Settings golden baselines

The DES-07 harness covers the real Settings, Account, Discovery preferences,
logout confirmation, delete confirmation/loading, and App information states.

The eight baselines were captured and visually reviewed during the DES-08 full
redesign verification pass on 2026-07-27. They run in the normal test gate.
Refresh them intentionally with:

```powershell
flutter test --update-goldens test/features/settings/settings_golden_test.dart
```

Inspect every changed PNG before committing it.

Unsupported Notifications, Privacy, Legal, block/report, and blocked-user
screens have no snapshots because the current product has no corresponding
contract or UI.
