import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/config.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../onboarding/registration_screen.dart';
import '../application/auth_providers.dart';
import '../application/auth_state.dart';
import '../domain/auth_models.dart';

enum _AuthStep { phone, code }

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  static const _resendDelay = 60;
  static const _demoPhoneNumber = '70000000001';

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  _AuthStep _step = _AuthStep.phone;
  bool _isSubmitting = false;
  int _secondsUntilResend = 0;
  String? _error;
  String? _demoCode;
  Timer? _timer;

  String get _phoneNumber {
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    }
    return digits;
  }

  bool get _isPhoneValid => RegExp(r'^7\d{10}$').hasMatch(_phoneNumber);
  bool get _isCodeValid => RegExp(r'^\d{6}$').hasMatch(_codeController.text);

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSubmitting) return;
    if (!_isPhoneValid) {
      setState(() => _error = 'Enter an 11-digit Russian phone number');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .sendCode(SendCodeRequest(_phoneNumber));
      if (!mounted) return;
      setState(() {
        _step = _AuthStep.code;
        _demoCode = AppConfig.isDemoMode ? response.demoVerificationCode : null;
      });
      _startResendTimer();
    } on Object catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmCode() async {
    if (_isSubmitting) return;
    if (!_isCodeValid) {
      setState(() => _error = 'Enter the 6-digit SMS code');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.checkCode(
        CheckCodeRequest(
          phoneNumber: _phoneNumber,
          verificationCode: _codeController.text,
        ),
      );
      final accountStatus = await repository.checkPhone(_phoneNumber);
      if (!mounted) return;

      if (accountStatus == AccountStatus.newUser) {
        context.push(
          Routes.register,
          extra: RegistrationArguments(phoneNumber: _phoneNumber),
        );
        return;
      }

      await ref
          .read(authControllerProvider.notifier)
          .login(
            LoginRequest(phoneNumber: _phoneNumber, code: _codeController.text),
          );
      if (!mounted) return;
      final authState = ref.read(authControllerProvider);
      if (authState.status == AuthStatus.authenticated) {
        context.go(Routes.discover);
      } else {
        setState(() {
          _error = _messageFor(authState.error ?? 'Unable to sign in');
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsUntilResend = _resendDelay);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsUntilResend <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsUntilResend = 0);
        return;
      }
      setState(() => _secondsUntilResend--);
    });
  }

  void _backToPhone() {
    _timer?.cancel();
    setState(() {
      _step = _AuthStep.phone;
      _secondsUntilResend = 0;
      _error = null;
      _demoCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCodeStep = _step == _AuthStep.code;
    return Scaffold(
      body: AppGradientScaffold(
        child: Padding(
          padding: AppTokens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isCodeStep)
                    IconButton(
                      onPressed: _isSubmitting ? null : _backToPhone,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  Text(
                    isCodeStep ? 'Enter SMS code' : 'Your phone number',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GlassSurface(
                child: TextField(
                  controller: isCodeStep ? _codeController : _phoneController,
                  enabled: !_isSubmitting,
                  keyboardType: isCodeStep
                      ? TextInputType.number
                      : TextInputType.phone,
                  maxLength: isCodeStep ? 6 : null,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    hintText: isCodeStep ? '000000' : '79991234567',
                    prefixIcon: Icon(
                      isCodeStep ? Icons.sms_outlined : Icons.phone_outlined,
                    ),
                    counterText: '',
                  ),
                ),
              ),
              if (!isCodeStep && AppConfig.isDemoMode) ...[
                const SizedBox(height: 8),
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
              if (_demoCode != null) ...[
                const SizedBox(height: 12),
                SafetyBadge(label: 'Demo verification code: $_demoCode'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              if (isCodeStep)
                Center(
                  child: TextButton(
                    onPressed: _secondsUntilResend == 0 && !_isSubmitting
                        ? _sendCode
                        : null,
                    child: Text(
                      _secondsUntilResend == 0
                          ? 'Send code again'
                          : 'Send again in $_secondsUntilResend s',
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: _isSubmitting
                      ? 'Please wait…'
                      : isCodeStep
                      ? 'Confirm code'
                      : 'Send code',
                  onPressed: _isSubmitting
                      ? () {}
                      : isCodeStep
                      ? _confirmCode
                      : _sendCode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    if (error is String) return error;
    return 'Something went wrong. Please try again.';
  }

  void _useDemoAccount() {
    _phoneController.text = _demoPhoneNumber;
    setState(() => _error = null);
  }
}
