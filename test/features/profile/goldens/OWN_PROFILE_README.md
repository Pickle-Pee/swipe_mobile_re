# DES-05 own-profile golden baselines

`own_profile_golden_test.dart` declares deterministic scenarios for:

- complete own profile;
- incomplete own profile;
- loading;
- initial error;
- edit saving state;
- saved public-profile preview.

The test cases are intentionally skipped until the user-requested full redesign
verification pass. No renderer or test command was run during DES-05. At that
checkpoint, remove the shared `skip`, run the existing Flutter golden update
workflow, inspect every generated PNG, and then commit the reviewed baselines.

Additional baselines to capture during that pass: missing photo, active
subscription, validation errors, photo upload progress/error, and unsaved
changes dialog. A reorder baseline remains blocked until backend-persisted
photo order exists.
