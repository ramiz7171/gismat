import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import 'session_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;
  bool _loading = false;
  bool _awaitingConfirmation = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) return; // button is disabled anyway
    setState(() => _loading = true);
    try {
      final needsConfirmation = await ref
          .read(authRepositoryProvider)
          .signUp(email: _email.text, password: _password.text);
      if (needsConfirmation && mounted) {
        setState(() => _awaitingConfirmation = true);
      }
      // If a session exists, the auth gate redirects to onboarding.
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_awaitingConfirmation) {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  size: 72, color: AppColors.primary),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.checkYourEmail,
                  style: AppTypography.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.confirmEmailBody(_email.text.trim()),
                  style: AppTypography.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              SecondaryButton(
                  label: l10n.signIn,
                  onPressed: () => context.go(Routes.signIn)),
            ],
          ),
        ),
      );
    }

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    List<Widget> stagger(List<Widget> children) {
      if (reduceMotion) return children;
      return [
        for (var i = 0; i < children.length; i++)
          children[i]
              .animate(delay: (70 * i).ms)
              .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.08, end: 0),
      ];
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: stagger([
                    Text(l10n.createAccount, style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(Icons.mail_outline)),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.isValidEmail(v ?? '')
                          ? null
                          : l10n.invalidEmail,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.isValidPassword(v ?? '')
                          ? null
                          : l10n.passwordTooShort,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                          labelText: l10n.confirmPassword,
                          prefixIcon: const Icon(Icons.lock_outline)),
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          v == _password.text ? null : l10n.passwordsDontMatch,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Required terms checkbox — sign-up stays disabled until checked.
                    CheckboxListTile(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text.rich(
                        TextSpan(
                          text: l10n.agreeToTerms,
                          style: AppTypography.body,
                          children: [
                            const TextSpan(text: '  ('),
                            TextSpan(
                              text: l10n.termsAndConditions,
                              style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.push(Routes.terms),
                            ),
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: l10n.privacyPolicy,
                              style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.push(Routes.privacy),
                            ),
                            const TextSpan(text: ')'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PrimaryButton(
                      label: l10n.createAccount,
                      loading: _loading,
                      onPressed: _agreed && !_loading ? _submit : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.alreadyHaveAccount,
                            style: AppTypography.body
                                .copyWith(color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: () =>
                              context.pushReplacement(Routes.signIn),
                          child: Text(l10n.signIn),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
