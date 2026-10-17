import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/forgot_password_controller.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final success = await ref
          .read(forgotPasswordControllerProvider.notifier)
          .sendOtp(email);
      if (success && mounted) {
        context.push(RoutePaths.verifyOtp, extra: {'email': email, 'isPasswordReset': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final s = AppStrings.of(context);

    ref.listen<AsyncValue<void>>(forgotPasswordControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, next.error)),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next.hasValue && !next.isLoading) {
        // This means success. Show a snackbar.
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.otpSentIfAccountExists),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(s.forgotPasswordTitle)),
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
                  s.resetPassword,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.forgotPasswordHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: s.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? s.emailRequired
                      : null,
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
                      : Text(s.sendOtp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
