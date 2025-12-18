import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/theme/app_colors.dart';
import 'package:sanad_app/core/theme/app_typography.dart';
import 'package:sanad_app/core/widgets/sanad_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    // Listen for successful password reset
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage!.contains('Password reset email sent')) {
        setState(() {
          _emailSent = true;
        });
      } else if (next.errorMessage != null) {
        _showErrorSnackbar(context, next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(s.resetPassword),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent
              ? _buildSuccessView(context, isDark, s)
              : _buildFormView(context, isDark, authState, s),
        ),
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    bool isDark,
    AuthState authState,
    S s,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // Header
          Text(
            s.resetPassword,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            s.enterEmailReset,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Email field
          AuthTextField(
            controller: _emailController,
            label: s.email,
            hint: s.enterEmail,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return s.fieldRequired;
              }
              if (!value.contains('@')) {
                return s.invalidEmail;
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Send button
          SanadButton(
            onPressed: _handlePasswordReset,
            text: s.sendResetLink,
            isLoading: authState.isLoading,
          ),

          const SizedBox(height: 16),

          // Back to login
          TextButton(
            onPressed: () => context.pop(),
            child: Text(s.backToLogin),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isDark, S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),

        // Success icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 48,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Success message
        Text(
          s.checkYourEmail,
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '${s.resetEmailSent}${_emailController.text}. ${s.followEmailInstructions}',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        // Back to login button
        SanadButton(onPressed: () => context.pop(), text: s.backToLogin),
      ],
    );
  }

  void _handlePasswordReset() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .sendPasswordResetEmail(_emailController.text.trim());
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
