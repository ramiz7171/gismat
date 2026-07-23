import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import 'settings_providers.dart';

/// Opens the report bottom sheet for [userId]. Reusable from cards, chat
/// and profile screens.
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String userName,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _ReportSheet(userId: userId, userName: userName),
    ),
  );
}

/// Shows a block confirmation dialog; blocks on confirm. Returns true if
/// the user was blocked.
Future<bool> confirmBlock(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String userName,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.block, style: AppTypography.h3),
      content: Text(l10n.blockConfirm(userName), style: AppTypography.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.block),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await ref.read(safetyRepositoryProvider).blockUser(userId);
    return true;
  } catch (e) {
    if (context.mounted) showAppError(context, e);
    return false;
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.userId, required this.userName});

  final String userId;
  final String userName;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  String? _reason;
  bool _submitting = false;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _submitting) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      final details = _detailsController.text.trim();
      await ref.read(safetyRepositoryProvider).reportUser(
            userId: widget.userId,
            reason: reason,
            details: details.isEmpty ? null : details,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackbar(l10n.reportSubmitted);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showAppError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reasons = <(String, String)>[
      ('fake', l10n.reportReasonFake),
      ('inappropriate', l10n.reportReasonInappropriate),
      ('harassment', l10n.reportReasonHarassment),
      ('underage', l10n.reportReasonUnderage),
      ('other', l10n.reportReasonOther),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
              child: Text(l10n.reportTitle(widget.userName),
                  style: AppTypography.h3),
            ),
            for (final (value, label) in reasons)
              RadioListTile<String>(
                value: value,
                groupValue: _reason,
                activeColor: AppColors.primary,
                title: Text(label, style: AppTypography.body),
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _reason = v),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
              child: TextField(
                controller: _detailsController,
                enabled: !_submitting,
                maxLines: 3,
                maxLength: 500,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: l10n.reportDetailsHint,
                  hintStyle: AppTypography.body
                      .copyWith(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: PrimaryButton(
                label: l10n.report,
                loading: _submitting,
                onPressed: _reason == null ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
