import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/reset_password_controller.dart';
import 'package:easy_localization/easy_localization.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String otp;
  const NewPasswordScreen({super.key, required this.email, required this.otp});
  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(resetPasswordControllerProvider.notifier)
          .reset(widget.email, widget.otp, _passwordController.text.trim());

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).successLoginNow),
            backgroundColor: Colors.green,
          ),
        );
        context.go(RoutePaths.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    final s = AppStrings.of(context);

    ref.listen<AsyncValue<void>>(resetPasswordControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(s.newPasswordTitle)),
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
                  s.setNewPassword,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: s.newPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? s.passwordMinLen : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: s.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return s.passwordsDoNotMatch;
                    }
                    return null;
                  },
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
                      : Text(s.resetPassword),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
