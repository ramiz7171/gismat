import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/env.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_providers.dart';
import '../domain/profile.dart';

/// Own profile: header, tier badge, verification CTA, photo grid with
/// add / delete / drag-reorder, and entry points to settings/paywall/admin.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _busy = false;

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    try {
      final photos = ref.read(myPhotosProvider).valueOrNull ?? const [];
      final profile = ref.read(myProfileProvider).valueOrNull;
      final limits = await ref.read(tierLimitsProvider.future);
      final cap = limits
          .firstWhere((t) => t.tier == (profile?.tier ?? 'basic'),
              orElse: () => limits.first)
          .maxPhotos;
      if (photos.length >= cap) {
        showAppSnackbar(l10n.photoLimitReached, isError: true);
        if (mounted) context.push(Routes.paywall);
        return;
      }
      final x = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85);
      if (x == null) return;
      setState(() => _busy = true);
      await ref
          .read(profileRepositoryProvider)
          .addPhoto(File(x.path), position: photos.length);
      await ref.read(myPhotosProvider.notifier).reload();
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePhoto(ProfilePhoto photo) async {
    final l10n = AppLocalizations.of(context);
    final photos = ref.read(myPhotosProvider).valueOrNull ?? const [];
    if (photos.length <= AppConstants.minPhotos) {
      showAppSnackbar(l10n.photosMinRequired(AppConstants.minPhotos),
          isError: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deletePhotoConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).deletePhoto(photo);
      final remaining = [...photos]..removeWhere((p) => p.id == photo.id);
      await ref.read(profileRepositoryProvider).reorderPhotos(remaining);
      await ref.read(myPhotosProvider.notifier).reload();
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final photos = [...ref.read(myPhotosProvider).valueOrNull ?? <ProfilePhoto>[]];
    if (newIndex > oldIndex) newIndex--;
    final moved = photos.removeAt(oldIndex);
    photos.insert(newIndex, moved);
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).reorderPhotos(photos);
      await ref.read(myPhotosProvider.notifier).reload();
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(myProfileProvider);
    final photos = ref.watch(myPhotosProvider).valueOrNull ?? const <ProfilePhoto>[];
    final repo = ref.read(profileRepositoryProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.errorLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.read(myProfileProvider.notifier).reload()),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final tierLabel = switch (profile.tier) {
          'pro' => l10n.tierPro,
          'max' => l10n.tierMax,
          _ => l10n.tierBasic,
        };
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                GismatAvatar(
                  url: photos.isEmpty
                      ? null
                      : repo.publicPhotoUrl(photos.first.storagePath),
                  size: 72,
                  verified: profile.isVerified,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${profile.fullName}, ${profile.age}',
                          style: AppTypography.h2),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Chip(
                            label: Text(tierLabel),
                            backgroundColor: profile.tier == 'basic'
                                ? AppColors.cyan50
                                : AppColors.primary,
                            labelStyle: AppTypography.caption.copyWith(
                                color: profile.tier == 'basic'
                                    ? AppColors.textPrimary
                                    : AppColors.onPrimary,
                                fontWeight: FontWeight.w600),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (profile.verificationStatus == 'pending')
                            Chip(
                              label: Text(l10n.verificationPendingBadge),
                              backgroundColor: AppColors.warning
                                  .withValues(alpha: 0.15),
                              labelStyle: AppTypography.caption,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.settingsTitle,
                  onPressed: () => context.push(Routes.settings),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            if (profile.bio != null && profile.bio!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(profile.bio!,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(Routes.editProfile),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.editProfile),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(Routes.paywall),
                    icon: const Icon(Icons.workspace_premium_outlined,
                        size: 18),
                    label: Text(l10n.upgrade),
                  ),
                ),
              ],
            ),
            if (!profile.isVerified &&
                profile.verificationStatus != 'pending') ...[
              const SizedBox(height: AppSpacing.md),
              ListTile(
                onTap: () => context.push(Routes.verify),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.lg)),
                tileColor: AppColors.cyan50,
                leading:
                    const Icon(Icons.verified, color: AppColors.primary),
                title: Text(l10n.verifyMe, style: AppTypography.h3),
                subtitle: Text(l10n.verificationBody,
                    style: AppTypography.caption),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
            if (profile.isAdmin) ...[
              const SizedBox(height: AppSpacing.md),
              ListTile(
                onTap: () => context.push(Routes.admin),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.lg)),
                tileColor: AppColors.surface,
                leading: const Icon(Icons.admin_panel_settings_outlined,
                    color: AppColors.primaryDark),
                title: Text(l10n.adminTitle, style: AppTypography.h3),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text(l10n.myPhotos, style: AppTypography.h3),
                const Spacer(),
                if (_busy)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ReorderableGridList(
              photos: photos,
              urlBuilder: repo.publicPhotoUrl,
              onReorder: _reorder,
              onDelete: _deletePhoto,
              onAdd: _addPhoto,
              mainLabel: l10n.mainPhoto,
              addLabel: l10n.addPhoto,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }
}

/// Reorderable photo grid (long-press drag), plus trailing "add" tile.
class ReorderableGridList extends StatelessWidget {
  const ReorderableGridList({
    super.key,
    required this.photos,
    required this.urlBuilder,
    required this.onReorder,
    required this.onDelete,
    required this.onAdd,
    required this.mainLabel,
    required this.addLabel,
  });

  final List<ProfilePhoto> photos;
  final String Function(String) urlBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(ProfilePhoto) onDelete;
  final VoidCallback onAdd;
  final String mainLabel;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          onReorder: onReorder,
          proxyDecorator: (child, _, _) => Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            child: child,
          ),
          itemBuilder: (context, i) {
            final photo = photos[i];
            return Padding(
              key: ValueKey(photo.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SizedBox(
                height: 84,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      child: CachedNetworkImage(
                        imageUrl: urlBuilder(photo.storagePath),
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const Skeleton(width: 84, height: 84, radius: 12),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    if (i == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(mainLabel,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.onPrimary)),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      onPressed: () => onDelete(photo),
                    ),
                    const Icon(Icons.drag_handle,
                        color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: addLabel,
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cyan50,
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                border: Border.all(color: AppColors.cyan100),
              ),
              child: const Icon(Icons.add_a_photo_outlined,
                  color: AppColors.primaryDark),
            ),
          ),
        ),
      ],
    );
  }
}
