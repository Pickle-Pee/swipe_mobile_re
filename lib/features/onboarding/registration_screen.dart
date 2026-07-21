import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import '../auth/application/auth_providers.dart';
import '../auth/application/auth_state.dart';
import '../auth/domain/auth_models.dart';

class RegistrationArguments {
  const RegistrationArguments({required this.phoneNumber});

  final String phoneNumber;
}

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  int step = 0;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _birthDate = TextEditingController();
  final _city = TextEditingController();
  String _selectedGender = '';
  final Set<String> _interests = {};
  bool _isSubmitting = false;
  String? _error;

  final interestPool = const [
    'Art',
    'Music',
    'Travel',
    'Food',
    'Sports',
    'Reading',
    'Nature',
    'Technology',
    'Dancing',
    'Gaming',
  ];

  bool get canGoNext {
    switch (step) {
      case 0:
        return _firstName.text.trim().isNotEmpty &&
            _lastName.text.trim().isNotEmpty;
      case 1:
        return _isAdultDate(_birthDate.text);
      case 2:
        return _selectedGender.isNotEmpty;
      case 3:
        return _city.text.trim().isNotEmpty;
      case 4:
        return _interests.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _birthDate.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isSubmitting || !canGoNext) return;
    if (step < 4) {
      setState(() {
        step++;
        _error = null;
      });
      return;
    }
    if (widget.phoneNumber.isEmpty) {
      setState(() => _error = 'Confirm your phone number first');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    await ref
        .read(authControllerProvider.notifier)
        .register(
          RegisterRequest(
            phoneNumber: widget.phoneNumber,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            dateOfBirth: _birthDate.text.trim(),
            gender: _selectedGender,
            cityName: _city.text.trim(),
          ),
        );
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go(Routes.discover);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _error = _messageFor(authState.error ?? 'Registration failed');
    });
  }

  void _goBack() {
    if (_isSubmitting) return;
    if (step == 0) {
      context.pop();
    } else {
      setState(() {
        step--;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: Padding(
          padding: AppTokens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    'Registration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (step + 1) / 5,
                color: AppTokens.blueSoft,
                backgroundColor: AppTokens.surface,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 24),
              Expanded(child: _content()),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: _isSubmitting
                      ? 'Creating profile…'
                      : step == 4
                      ? 'Continue to discovery'
                      : 'Next',
                  onPressed: _isSubmitting || !canGoNext ? () {} : _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (step) {
      case 0:
        return GlassSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstName,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'First name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastName,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Last name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
        );
      case 1:
        return GlassSurface(
          child: TextField(
            controller: _birthDate,
            keyboardType: TextInputType.datetime,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Date of birth (YYYY-MM-DD)',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
          ),
        );
      case 2:
        return GlassSurface(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                const {
                      'Woman': 'female',
                      'Man': 'male',
                      'Non-binary': 'non-binary',
                    }.entries
                    .map(
                      (entry) => ChoiceChip(
                        label: Text(entry.key),
                        selected: _selectedGender == entry.value,
                        onSelected: (_) =>
                            setState(() => _selectedGender = entry.value),
                      ),
                    )
                    .toList(),
          ),
        );
      case 3:
        return GlassSurface(
          child: TextField(
            controller: _city,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'City',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
        );
      default:
        return GlassSurface(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: interestPool
                  .map(
                    (interest) => FilterChip(
                      label: Text(interest),
                      selected: _interests.contains(interest),
                      onSelected: (_) => setState(() {
                        _interests.contains(interest)
                            ? _interests.remove(interest)
                            : _interests.add(interest);
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
    }
  }

  bool _isAdultDate(String value) {
    final date = DateTime.tryParse(value.trim());
    if (date == null) return false;
    final now = DateTime.now();
    final adultThreshold = DateTime(now.year - 18, now.month, now.day);
    return !date.isAfter(adultThreshold);
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    if (error is String) return error;
    return 'Something went wrong. Please try again.';
  }
}
