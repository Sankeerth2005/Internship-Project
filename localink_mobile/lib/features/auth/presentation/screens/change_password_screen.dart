import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/app_error_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validation/app_validators.dart';
import '../../../../core/auth/role_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../../shared/presentation/widgets/app_background.dart';
import '../../../shared/presentation/widgets/app_back_button.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../shared/presentation/widgets/app_text_field.dart';
import '../../../shared/presentation/widgets/shake_widget.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      _shakeKey.currentState?.shake();
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await DioClient().dio.post(
        'auth/change-password',
        data: {
          'currentPassword': _currentCtrl.text,
          'newPassword': _newCtrl.text,
        },
      );

      if (!mounted) return;
      final message = response.data is Map
          ? (response.data['message']?.toString() ??
              'Password changed successfully.')
          : 'Password changed successfully.';

      AppFeedback.showSuccess(context, message);
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _shakeKey.currentState?.shake();
      AppFeedback.showError(context, AppErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else if (auth is AuthAuthenticated) {
                        context.go(RoleRoutes.homeForRole(auth.userType));
                      } else {
                        context.go('/login');
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ShakeWidget(
                    key: _shakeKey,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter your current password and choose a new one.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedTextColor,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          AppTextField(
                            controller: _currentCtrl,
                            labelText: 'Current password',
                            isPassword: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: (v) =>
                                AppValidators.password(v, requireStrong: false),
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _newCtrl,
                            labelText: 'New password',
                            isPassword: true,
                            prefixIcon: Icons.lock_rounded,
                            validator: AppValidators.password,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _confirmCtrl,
                            labelText: 'Confirm new password',
                            isPassword: true,
                            prefixIcon: Icons.lock_rounded,
                            validator: (v) => AppValidators.confirmPassword(
                              v,
                              _newCtrl.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Requirement(
                            label: 'At least 8 characters',
                            ok: AppValidators.hasMinLength(_newCtrl.text),
                          ),
                          _Requirement(
                            label: 'Uppercase letter',
                            ok: AppValidators.hasUpper(_newCtrl.text),
                          ),
                          _Requirement(
                            label: 'Lowercase letter',
                            ok: AppValidators.hasLower(_newCtrl.text),
                          ),
                          _Requirement(
                            label: 'Number',
                            ok: AppValidators.hasDigit(_newCtrl.text),
                          ),
                          _Requirement(
                            label: 'Special character (@\$!%*?&)',
                            ok: AppValidators.hasSpecial(_newCtrl.text),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: 'Update password',
                            isLoading: _loading,
                            onPressed: _loading ? null : _submit,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final String label;
  final bool ok;

  const _Requirement({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? AppTheme.tricolorGreen : AppTheme.softMutedTextColor,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ok ? AppTheme.textColor : AppTheme.mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
