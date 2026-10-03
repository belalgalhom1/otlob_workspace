import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/token_service.dart';
import '../providers/verify_otp_controller.dart';
import '../providers/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String password;
  final bool isPasswordReset;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.password = '',
    this.isPasswordReset = false,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  late final TextEditingController _emailController;
  bool _isLoadingEmail = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    if (widget.email.isEmpty) {
      _loadEmail();
    }
  }

  Future<void> _loadEmail() async {
    setState(() => _isLoadingEmail = true);
    final tokenService = ref.read(tokenServiceProvider);
    final email = await tokenService.getUserEmail();
    if (email != null && mounted) {
      setState(() {
        _emailController.text = email;
      });
    }
    if (mounted) setState(() => _isLoadingEmail = false);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final otp = _otpController.text.trim();
      final email = _emailController.text.trim();
      final success = await ref
          .read(verifyOtpControllerProvider.notifier)
          .verify(
            email,
            otp,
            isPasswordReset: widget.isPasswordReset,
            password: widget.password,
          );
      if (success && mounted) {
        if (widget.isPasswordReset) {
          context.push(
            RoutePaths.newPassword,
            extra: {'email': email, 'otp': otp},
          );
        } else {
          // Registration flow: VerifyOtpController auto-logs-in when a
          // password is available. Once authenticated, the router redirects
          // to home; only send the user to login if that did not happen.
          if (ref.read(authControllerProvider) != AuthStatus.authenticated) {
            context.go(RoutePaths.login);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyOtpControllerProvider);
    final s = AppStrings.of(context);

    ref.listen<AsyncValue<void>>(verifyOtpControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().tr()),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next is AsyncData && !next.isLoading && !widget.isPasswordReset) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.accountVerifiedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(s.verifyOtp)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  s.checkYourEmail,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_emailController.text.isNotEmpty)
                  Text(
                    s.otpSentToEmail(_emailController.text),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 32),
                if (_isLoadingEmail)
                  const Center(child: CircularProgressIndicator())
                else if (_emailController.text.isEmpty) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: s.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? s.emailRequired : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8.0,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: s.verificationCode,
                    counterText: "",
                  ),
                  validator: (v) =>
                      (v == null || v.length < 4) ? s.enterValidCode : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(s.verifyCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
