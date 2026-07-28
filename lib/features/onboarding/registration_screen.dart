import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/midnight_components.dart';
import '../auth/application/auth_providers.dart';
import '../auth/domain/auth_models.dart';
import '../auth/presentation/auth_components.dart';
import '../auth/presentation/phone_auth_screen.dart';
import 'domain/onboarding_models.dart';

class RegistrationArguments {
  const RegistrationArguments({required this.phoneNumber});

  final String phoneNumber;
}

enum _RegistrationStep { identity, birthday, gender, city, review }

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cityController = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();

  _RegistrationStep _step = _RegistrationStep.identity;
  DateTime? _dateOfBirth;
  String _gender = '';
  bool _isSubmitting = false;
  Map<String, String> _fieldErrors = const {};
  String? _error;
  bool _accountExists = false;

  int get _stepNumber => _RegistrationStep.values.indexOf(_step) + 1;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _cityController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    final errors = _validateCurrentStep();
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
        _error = null;
      });
      return;
    }
    if (_step != _RegistrationStep.review) {
      setState(() {
        _step = _RegistrationStep.values[_stepNumber];
        _fieldErrors = const {};
        _error = null;
      });
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (widget.phoneNumber.isEmpty) {
      setState(() {
        _error = 'Verify your phone number before creating an account.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _accountExists = false;
    });
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          RegisterRequest(
            phoneNumber: widget.phoneNumber,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            dateOfBirth: _dateOnly(_dateOfBirth!),
            gender: _gender,
            cityName: _cityController.text.trim(),
          ),
        );
    if (!mounted) return;
    if (success) {
      context.go(Routes.bootstrap);
      return;
    }
    final error = ref.read(authControllerProvider).error;
    setState(() {
      _isSubmitting = false;
      _accountExists = _isAccountConflict(error);
      _error = _messageFor(error ?? 'Registration failed');
    });
  }

  void _back() {
    if (_isSubmitting) return;
    final index = _RegistrationStep.values.indexOf(_step);
    if (index == 0) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.registrationPhone);
      }
      return;
    }
    setState(() {
      _step = _RegistrationStep.values[index - 1];
      _fieldErrors = const {};
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: _title,
      subtitle: _subtitle,
      onBack: _back,
      stepLabel: '$_stepNumber of ${_RegistrationStep.values.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RegistrationProgress(
            step: _stepNumber,
            total: _RegistrationStep.values.length,
          ),
          const SizedBox(height: AppTokens.space20),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: AuthFormPanel(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey<_RegistrationStep>(_step),
                    child: _content(),
                  ),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.space12),
            AuthErrorBanner(message: _error!),
          ],
          if (_accountExists) ...[
            const SizedBox(height: AppTokens.space8),
            TextButton(
              key: const Key('registration-sign-in'),
              onPressed: _isSubmitting ? null : _signInInstead,
              child: const Text('Sign in instead'),
            ),
          ],
          const SizedBox(height: AppTokens.space20),
          PrimaryActionButton(
            key: const Key('registration-continue'),
            label: _step == _RegistrationStep.review
                ? 'Create account'
                : 'Continue',
            icon: Icons.arrow_forward_rounded,
            loading: _isSubmitting,
            onPressed: _isSubmitting ? null : _continue,
          ),
        ],
      ),
    );
  }

  Widget _content() {
    switch (_step) {
      case _RegistrationStep.identity:
        return AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('registration-first-name'),
                controller: _firstNameController,
                focusNode: _firstNameFocusNode,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                onChanged: (_) => _clearFieldError('first_name'),
                onSubmitted: (_) => _lastNameFocusNode.requestFocus(),
                decoration: InputDecoration(
                  labelText: 'First name',
                  hintText: 'How people will see you',
                  errorText: _fieldErrors['first_name'],
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              TextField(
                key: const Key('registration-last-name'),
                controller: _lastNameController,
                focusNode: _lastNameFocusNode,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.familyName],
                onChanged: (_) => _clearFieldError('last_name'),
                onSubmitted: (_) => _continue(),
                decoration: InputDecoration(
                  labelText: 'Last name',
                  hintText: 'Required by the current account profile',
                  errorText: _fieldErrors['last_name'],
                ),
              ),
            ],
          ),
        );
      case _RegistrationStep.birthday:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('registration-birthday'),
              controller: _birthDateController,
              readOnly: true,
              enabled: !_isSubmitting,
              onTap: _pickBirthday,
              decoration: InputDecoration(
                labelText: 'Date of birth',
                hintText: 'YYYY-MM-DD',
                prefixIcon: const Icon(Icons.cake_outlined),
                errorText: _fieldErrors['date_of_birth'],
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            Text(
              'You must be at least 18. Your birthday is sent as an ISO date, without a time zone.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      case _RegistrationStep.gender:
        return _GenderSelector(
          selected: _gender,
          errorText: _fieldErrors['gender'],
          onSelected: (value) {
            if (_isSubmitting) return;
            setState(() {
              _gender = value;
              _fieldErrors = {..._fieldErrors}..remove('gender');
            });
          },
        );
      case _RegistrationStep.city:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('registration-city'),
              controller: _cityController,
              focusNode: _cityFocusNode,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.addressCity],
              onChanged: (_) => _clearFieldError('city_name'),
              onSubmitted: (_) => _continue(),
              decoration: InputDecoration(
                labelText: 'City',
                hintText: 'Enter the city stored by Swipe',
                prefixIcon: const Icon(Icons.location_on_outlined),
                errorText: _fieldErrors['city_name'],
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            Text(
              'The current server accepts only a city from its catalog and will validate it when the account is created.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      case _RegistrationStep.review:
        return _RegistrationReview(
          phoneNumber: widget.phoneNumber,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          city: _cityController.text.trim(),
        );
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year - 18, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(lastDate.year - 7),
      firstDate: DateTime(1900),
      lastDate: lastDate,
      helpText: 'Choose your date of birth',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateOfBirth = selected;
      _birthDateController.text = _dateOnly(selected);
      _fieldErrors = {..._fieldErrors}..remove('date_of_birth');
    });
  }

  Map<String, String> _validateCurrentStep() {
    final errors = <String, String>{};
    switch (_step) {
      case _RegistrationStep.identity:
        if (_firstNameController.text.trim().isEmpty) {
          errors['first_name'] = 'First name is required';
        }
        if (_lastNameController.text.trim().isEmpty) {
          errors['last_name'] = 'Last name is required';
        }
      case _RegistrationStep.birthday:
        final date = _dateOfBirth;
        if (date == null) {
          errors['date_of_birth'] = 'Choose your date of birth';
        } else if (!isAtLeastEighteen(date)) {
          errors['date_of_birth'] = 'You must be at least 18';
        }
      case _RegistrationStep.gender:
        if (_gender.isEmpty) errors['gender'] = 'Choose a gender';
      case _RegistrationStep.city:
        if (_cityController.text.trim().isEmpty) {
          errors['city_name'] = 'City is required';
        }
      case _RegistrationStep.review:
        if (_firstNameController.text.trim().isEmpty ||
            _lastNameController.text.trim().isEmpty ||
            _dateOfBirth == null ||
            _gender.isEmpty ||
            _cityController.text.trim().isEmpty) {
          errors['review'] = 'Review the required account details';
        }
    }
    return errors;
  }

  void _clearFieldError(String field) {
    if (_fieldErrors[field] == null && _error == null) return;
    setState(() {
      _fieldErrors = {..._fieldErrors}..remove(field);
      _error = null;
      _accountExists = false;
    });
  }

  void _signInInstead() {
    context.go(
      Routes.authPhone,
      extra: PhoneAuthArguments(
        intent: AuthIntent.login,
        initialPhoneNumber: widget.phoneNumber,
      ),
    );
  }

  bool _isAccountConflict(Object? error) {
    if (error is! ValidationApiException) return false;
    return error.message.toLowerCase().contains('already registered') ||
        error.message.toLowerCase().contains('already exists');
  }

  String _messageFor(Object error) {
    if (error is NetworkApiException) {
      return 'Check your connection and try again. Your registration details are still here.';
    }
    if (error is ValidationApiException) {
      final message = error.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('already exists')) {
        return 'An account with this phone number already exists.';
      }
      if (message.contains('city')) {
        return 'That city is not available in the current catalog.';
      }
      return error.message;
    }
    if (error is ServerApiException) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    if (error is ApiException) return error.message;
    if (error is String) return error;
    return 'We could not create the account. Please try again.';
  }

  String get _title => switch (_step) {
    _RegistrationStep.identity => 'What should we call you?',
    _RegistrationStep.birthday => 'When is your birthday?',
    _RegistrationStep.gender => 'How do you identify?',
    _RegistrationStep.city => 'Where are you based?',
    _RegistrationStep.review => 'Review your account',
  };

  String get _subtitle => switch (_step) {
    _RegistrationStep.identity =>
      'These are the real identity fields required by the current account contract.',
    _RegistrationStep.birthday =>
      'We use your date of birth to show an accurate age.',
    _RegistrationStep.gender =>
      'Your choice is stored as the canonical value supported by Swipe.',
    _RegistrationStep.city => 'Use the city name associated with your profile.',
    _RegistrationStep.review =>
      'Your phone is already verified. Create the account when these details look right.',
  };
}

class _RegistrationProgress extends StatelessWidget {
  const _RegistrationProgress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of $total',
      value: 'Step $step of $total',
      child: LinearProgressIndicator(
        value: step / total,
        minHeight: 5,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final String? errorText;

  static const _options = {
    'Woman': 'female',
    'Man': 'male',
    'Non-binary': 'non-binary',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._options.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space12),
            child: Semantics(
              selected: selected == entry.value,
              button: true,
              label:
                  '${entry.key}, ${selected == entry.value ? 'selected' : 'not selected'}',
              excludeSemantics: true,
              child: SizedBox(
                width: double.infinity,
                child: ChoiceChip(
                  key: ValueKey<String>('registration-gender-${entry.value}'),
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(entry.key, textAlign: TextAlign.center),
                  ),
                  selected: selected == entry.value,
                  onSelected: (_) => onSelected(entry.value),
                  selectedColor: AppTokens.brandViolet.withValues(alpha: 0.26),
                  backgroundColor: AppTokens.backgroundElevated,
                  side: BorderSide(
                    color: selected == entry.value
                        ? AppTokens.brandViolet
                        : AppTokens.glassBorder,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Semantics(
            liveRegion: true,
            child: Text(
              errorText!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTokens.error),
            ),
          ),
      ],
    );
  }
}

class _RegistrationReview extends StatelessWidget {
  const _RegistrationReview({
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
  });

  final String phoneNumber;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String gender;
  final String city;

  @override
  Widget build(BuildContext context) {
    final rows = {
      'Phone': phoneNumber,
      'Name': '$firstName $lastName'.trim(),
      'Birthday': dateOfBirth == null ? '' : _dateOnly(dateOfBirth!),
      'Gender': _genderLabel(gender),
      'City': city,
    };
    return Column(
      children: rows.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  String _genderLabel(String value) => switch (value) {
    'female' => 'Woman',
    'male' => 'Man',
    'non-binary' => 'Non-binary',
    _ => value,
  };
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
