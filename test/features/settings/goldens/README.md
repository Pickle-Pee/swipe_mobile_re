# Settings golden baselines

The DES-07 harness covers the real Settings, Account, Discovery preferences,
logout confirmation, delete confirmation/loading, and App information states.

Baseline PNG capture is intentionally deferred until the requested complete
redesign verification pass. Generate the files with:

```bash
flutter test --update-goldens test/features/settings/settings_golden_test.dart
```

Unsupported Notifications, Privacy, Legal, block/report, and blocked-user
screens have no snapshots because the current product has no corresponding
contract or UI.
