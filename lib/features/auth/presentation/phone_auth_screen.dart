import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/config.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/midnight_components.dart';
import '../../onboarding/registration_screen.dart';
import '../application/auth_providers.dart';
import '../domain/auth_models.dart';
import 'auth_components.dart';

enum AuthIntent { login, registration }

class PhoneAuthArguments {
  const PhoneAuthArguments({
    required this.intent,
    this.initialPhoneNumber = '',
  });

  final AuthIntent intent;
  final String initialPhoneNumber;
}

enum _AuthStep { phone, code }

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({
    super.key,
    this.intent = AuthIntent.login,
    this.initialPhoneNumber = '',
  });

  final AuthIntent intent;
  final String initialPhoneNumber;

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  static const _resendDelaySeconds = 60;
  static const _demoPhoneNumber = '70000000001';

  late AuthIntent _intent;
  late final TextEditingController _phoneController;
  final _codeController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();

  _AuthStep _step = _AuthStep.phone;
  bool _isSubmitting = false;
  int _secondsUntilResend = 0;
  String? _phoneError;
  String? _codeError;
  String? _error;
  String? _demoCode;
  AccountStatus? _mismatchedAccount;
  Timer? _timer;

  String get _phoneNumber {
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    }
    return digits;
  }

  bool get _isPhoneValid => RegExp(r'^7\d{10}$').hasMatch(_phoneNumber);
  bool get _isCodeValid =>
      RegExp(r'^\d{6}$').hasMatch(_codeController.text.trim());

  @override
  void initState() {
    super.initState();
    _intent = widget.intent;
    _phoneController = TextEditingController(text: widget.initialPhoneNumber);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSubmitting) return;
    if (!_isPhoneValid) {
      setState(() {
        _phoneError = 'Enter an 11-digit phone number starting with 7';
        _error = null;
      });
      _phoneFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _phoneError = null;
      _codeError = null;
      _error = null;
      _mismatchedAccount = null;
    });
    try {
      final response = await ref
          .read(authControllerProvider.notifier)
          .sendCode(SendCodeRequest(_phoneNumber));
      if (!mounted) return;
      setState(() {
        _step = _AuthStep.code;
        _demoCode = AppConfig.isDemoMode ? response.demoVerificationCode : null;
        _codeController.clear();
      });
      _startResendTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocusNode.requestFocus();
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmCode() async {
    if (_isSubmitting) return;
    if (!_isCodeValid) {
      setState(() {
        _codeError = 'Enter the six-digit code';
        _error = null;
      });
      _codeFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _codeError = null;
      _error = null;
      _mismatchedAccount = null;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      final code = _codeController.text.trim();
      await repository.checkCode(
        CheckCodeRequest(phoneNumber: _phoneNumber, verificationCode: code),
      );
      final accountStatus = await repository.checkPhone(_phoneNumber);
      if (!mounted) return;

      final wantsRegistration = _intent == AuthIntent.registration;
      final accountMatches =
          (wantsRegistration && accountStatus == AccountStatus.newUser) ||
          (!wantsRegistration && accountStatus == AccountStatus.existingUser);
      if (!accountMatches) {
        setState(() {
          _mismatchedAccount = accountStatus;
          _error = accountStatus == AccountStatus.existingUser
              ? 'An account with this phone number already exists.'
              : 'No account was found for this phone number.';
        });
        return;
      }

      if (accountStatus == AccountStatus.newUser) {
        await context.push(
          Routes.register,
          extra: RegistrationArguments(phoneNumber: _phoneNumber),
        );
        return;
      }

      final success = await ref
          .read(authControllerProvider.notifier)
          .login(LoginRequest(phoneNumber: _phoneNumber, code: code));
      if (!mounted) return;
      if (success) {
        context.go(Routes.bootstrap);
      } else {
        setState(() {
          _error = _messageFor(
            ref.read(authControllerProvider).error ?? 'Unable to sign in',
          );
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    if (_isSubmitting || _secondsUntilResend > 0) return;
    await _sendCode();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsUntilResend = _resendDelaySeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsUntilResend <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsUntilResend = 0);
        return;
      }
      setState(() => _secondsUntilResend--);
    });
  }

  void _back() {
    if (_isSubmitting) return;
    if (_step == _AuthStep.phone) {
      context.go(Routes.welcome);
      return;
    }
    _timer?.cancel();
    setState(() {
      _step = _AuthStep.phone;
      _secondsUntilResend = 0;
      _codeController.clear();
      _codeError = null;
      _error = null;
      _demoCode = null;
      _mismatchedAccount = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCodeStep = _step == _AuthStep.code;
    final registering = _intent == AuthIntent.registration;
    return AuthScaffold(
      title: isCodeStep
          ? 'Enter your code'
          : registering
          ? 'Create your account'
          : 'Welcome back',
      subtitle: isCodeStep
          ? 'We sent a six-digit code to ${_displayPhone(_phoneNumber)}.'
          : registering
          ? 'Start with the phone number you want to use for Swipe.'
          : 'Sign in with the phone number connected to your profile.',
      onBack: _back,
      stepLabel: isCodeStep ? 'Code' : 'Phone',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormPanel(
              child: isCodeStep ? _buildCodeForm() : _buildPhoneForm(),
            ),
            if (_demoCode != null) ...[
              const SizedBox(height: AppTokens.space12),
              _DemoCodeNotice(code: _demoCode!),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppTokens.space12),
              AuthErrorBanner(message: _error!),
            ],
            if (_mismatchedAccount != null) ...[
              const SizedBox(height: AppTokens.space8),
              TextButton(
                key: const Key('switch-auth-intent'),
                onPressed: _isSubmitting ? null : _switchIntent,
                child: Text(
                  _mismatchedAccount == AccountStatus.existingUser
                      ? 'Sign in instead'
                      : 'Create an account instead',
                ),
              ),
            ],
            const Spacer(),
            if (isCodeStep)
              ResendCodeControl(
                secondsRemaining: _secondsUntilResend,
                loading: _isSubmitting,
                onResend: _resendCode,
              ),
            const SizedBox(height: AppTokens.space8),
            PrimaryActionButton(
              key: const Key('auth-submit'),
              label: isCodeStep
                  ? registering
                        ? 'Continue'
                        : 'Sign in'
                  : 'Send code',
              icon: Icons.arrow_forward_rounded,
              loading: _isSubmitting,
              onPressed: _isSubmitting
                  ? null
                  : isCodeStep
                  ? _confirmCode
                  : _sendCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('phone-input'),
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+-]')),
            LengthLimitingTextInputFormatter(18),
          ],
          onChanged: (_) => setState(() {
            _phoneError = null;
            _error = null;
          }),
          onSubmitted: (_) => _sendCode(),
          decoration: InputDecoration(
            labelText: 'Phone number',
            hintText: '79991234567',
            prefixIcon: const Icon(Icons.phone_outlined),
            errorText: _phoneError,
          ),
        ),
        if (AppConfig.isDemoMode) ...[
          const SizedBox(height: AppTokens.space8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('use-demo-account'),
              onPressed: _isSubmitting ? null : _useDemoAccount,
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Use demo account · 70000000001'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCodeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtpInput(
          controller: _codeController,
          focusNode: _codeFocusNode,
          enabled: !_isSubmitting,
          errorText: _codeError,
          onChanged: (_) => setState(() {
            _codeError = null;
            _error = null;
            _mismatchedAccount = null;
          }),
          onSubmitted: (_) => _confirmCode(),
        ),
        const SizedBox(height: AppTokens.space8),
        TextButton(
          key: const Key('change-phone'),
          onPressed: _isSubmitting ? null : _back,
          child: const Text('Use a different phone number'),
        ),
      ],
    );
  }

  void _switchIntent() {
    setState(() {
      _intent = _mismatchedAccount == AccountStatus.existingUser
          ? AuthIntent.login
          : AuthIntent.registration;
      _mismatchedAccount = null;
      _error = null;
    });
  }

  void _useDemoAccount() {
    _phoneController.text = _demoPhoneNumber;
    _phoneController.selection = TextSelection.collapsed(
      offset: _phoneController.text.length,
    );
    setState(() {
      _phoneError = null;
      _error = null;
    });
  }

  String _messageFor(Object error) {
    if (error is NetworkApiException) {
      return 'Check your connection and try again. Your entered data is still here.';
    }
    if (error is ValidationApiException) {
      final details = error.details;
      final code = details is Map<String, dynamic> ? details['code'] : null;
      if (code == 604) return 'That code is not valid. Check it and try again.';
      if (code == 666) return 'Enter a valid phone number starting with 7.';
      return error.message;
    }
    if (error is ServerApiException) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    if (error is ApiException) return error.message;
    if (error is String) return error;
    return 'Something went wrong. Please try again.';
  }

  String _displayPhone(String value) {
    if (value.length != 11) return value;
    return '+${value[0]} ${value.substring(1, 4)} ${value.substring(4, 7)} '
        '${value.substring(7, 9)} ${value.substring(9)}';
  }
}

class _DemoCodeNotice extends StatelessWidget {
  const _DemoCodeNotice({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Demo verification code $code',
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space12),
        decoration: BoxDecoration(
          color: AppTokens.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: AppTokens.success.withValues(alpha: 0.34)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.science_outlined,
              color: AppTokens.success,
              size: AppTokens.iconCompact,
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: Text(
                'Demo verification code: $code',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTokens.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
