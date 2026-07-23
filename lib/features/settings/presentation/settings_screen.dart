import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/session_providers.dart';
import '../../notifications/data/push_service.dart';
import 'locale_provider.dart';
import 'settings_providers.dart';

const _languageNames = <String, String>{
  'az': 'Azərbaycanca',
  'en': 'English',
  'ru': 'Русский',
  'tr': 'Türkçe',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final selectedLocale = ref.watch(appLocaleProvider);
    final currentCode =
        selectedLocale?.languageCode ?? Localizations.localeOf(context).languageCode;
    final languageName = _languageNames[currentCode] ?? _languageNames['en']!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            _SectionHeader(l10n.language),
            ListTile(
              minVerticalPadding: AppSpacing.md,
              leading: const Icon(Icons.language, color: AppColors.primaryDark),
              title: Text(l10n.language, style: AppTypography.bodyLarge),
              subtitle: Text(languageName, style: AppTypography.caption),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => _showLanguageSheet(context, ref, currentCode),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _SectionHeader(l10n.notificationsSetting),
            SwitchListTile(
              value: ref.watch(notificationsEnabledProvider),
              activeColor: AppColors.primary,
              title:
                  Text(l10n.notificationsSetting, style: AppTypography.bodyLarge),
              onChanged: (v) =>
                  ref.read(notificationsEnabledProvider.notifier).set(v),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _SectionHeader(l10n.privacySection),
            SwitchListTile(
              value: profile?.isSnoozed ?? false,
              activeColor: AppColors.primary,
              title: Text(l10n.snoozeMode, style: AppTypography.bodyLarge),
              subtitle: Text(l10n.snoozeModeHint, style: AppTypography.caption),
              onChanged: profile == null
                  ? null
                  : (v) => _setSnoozed(context, ref, v),
            ),
            SwitchListTile(
              value: ref.watch(blurExplicitImagesProvider),
              activeColor: AppColors.primary,
              title: Text(l10n.blurExplicit, style: AppTypography.bodyLarge),
              onChanged: (v) =>
                  ref.read(blurExplicitImagesProvider.notifier).set(v),
            ),
            ListTile(
              minVerticalPadding: AppSpacing.md,
              leading: const Icon(Icons.block, color: AppColors.primaryDark),
              title: Text(l10n.blockedUsers, style: AppTypography.bodyLarge),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => context.push(Routes.blockedUsers),
            ),
            ListTile(
              minVerticalPadding: AppSpacing.md,
              leading:
                  const Icon(Icons.shield_outlined, color: AppColors.primaryDark),
              title: Text(l10n.safetyCenter, style: AppTypography.bodyLarge),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => context.push(Routes.safety),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _SectionHeader(l10n.aboutApp),
            ListTile(
              minVerticalPadding: AppSpacing.md,
              leading:
                  const Icon(Icons.description_outlined, color: AppColors.primaryDark),
              title:
                  Text(l10n.termsAndConditions, style: AppTypography.bodyLarge),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => context.push(Routes.terms),
            ),
            ListTile(
              minVerticalPadding: AppSpacing.md,
              leading:
                  const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryDark),
              title: Text(l10n.privacyPolicy, style: AppTypography.bodyLarge),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => context.push(Routes.privacy),
            ),
            ListTile(
              minVerticalPadding: AppSpacing.md,
              leading: const Icon(Icons.info_outline, color: AppColors.primaryDark),
              title: Text(l10n.version, style: AppTypography.bodyLarge),
              trailing: Text('1.0.0', style: AppTypography.caption),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _SectionHeader(l10n.accountSection),
            ListTile(
              minVerticalPadding: AppSpacing.md,
              leading: const Icon(Icons.logout, color: AppColors.textSecondary),
              title: Text(l10n.signOut, style: AppTypography.bodyLarge),
              onTap: () => _confirmSignOut(context, ref),
            ),
            ListTile(
              minVerticalPadding: AppSpacing.md,
              leading:
                  const Icon(Icons.delete_forever_outlined, color: AppColors.error),
              title: Text(
                l10n.deleteAccount,
                style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
              ),
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet(
      BuildContext context, WidgetRef ref, String currentCode) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
                child: Text(l10n.language, style: AppTypography.h3),
              ),
              for (final locale in supportedLocales)
                RadioListTile<String>(
                  value: locale.languageCode,
                  groupValue: currentCode,
                  activeColor: AppColors.primary,
                  title: Text(_languageNames[locale.languageCode]!,
                      style: AppTypography.bodyLarge),
                  onChanged: (code) {
                    if (code != null) {
                      ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
                    }
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setSnoozed(
      BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile({'is_snoozed': value});
      await ref.read(myProfileProvider.notifier).reload();
    } catch (e) {
      if (context.mounted) showAppError(context, e);
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOut, style: AppTypography.h3),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await PushService.unregisterDevice();
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      if (context.mounted) showAppError(context, e);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccount, style: AppTypography.h3),
        content: Text(l10n.deleteAccountConfirm, style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(supabaseClientProvider).functions.invoke('delete-account');
      await PushService.unregisterDevice();
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      if (context.mounted) showAppError(context, e);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
