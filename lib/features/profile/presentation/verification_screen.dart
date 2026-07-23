import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../auth/presentation/session_providers.dart';

/// Photo verification: take a selfie → uploaded for admin review.
/// Architected so an automated face-match can replace manual review later
/// (see docs/DECISIONS.md).
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _busy = false;

  Future<void> _takeSelfie() async {
    final l10n = AppLocalizations.of(context);
    try {
      final x = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: 1200,
          imageQuality: 85);
      if (x == null) return;
      setState(() => _busy = true);
      final bytes = await x.readAsBytes();
      await ref
          .read(profileRepositoryProvider)
          .submitVerificationSelfie(bytes);
      await ref.read(myProfileProvider.notifier).reload();
      if (mounted) {
        showAppSnackbar(l10n.verificationSubmitted);
        context.pop();
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyMe)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.verified, size: 84, color: AppColors.primary),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.verifyMe,
                  style: AppTypography.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.verificationBody,
                  style: AppTypography.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                  label: l10n.takeSelfie,
                  icon: Icons.camera_alt_outlined,
                  loading: _busy,
                  onPressed: _busy ? null : _takeSelfie),
            ],
          ),
        ),
      ),
    );
  }
}
