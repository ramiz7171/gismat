import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/env.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../auth/presentation/session_providers.dart';

/// Post-register onboarding: name → DOB(18+) → gender/interest →
/// photos(min 3) → location → bio. The auth gate keeps the user here until
/// the profile row exists and at least 3 photos are uploaded.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 6;
  final _controller = PageController();
  int _step = 0;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  DateTime? _dob;
  String? _gender;
  final Set<String> _interestedIn = {};
  final _bio = TextEditingController();
  final List<XFile> _pickedPhotos = [];
  bool _busy = false;
  bool _profileSaved = false;

  @override
  void initState() {
    super.initState();
    // Resume mid-onboarding: profile may already exist with photos missing.
    final profile = ref.read(myProfileProvider).valueOrNull;
    if (profile != null) {
      _firstName.text = profile.firstName;
      _lastName.text = profile.lastName;
      _dob = profile.dateOfBirth;
      _gender = profile.gender;
      _interestedIn.addAll(profile.interestedIn);
      _bio.text = profile.bio ?? '';
      _profileSaved = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _controller.animateToPage(step,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic);
  }

  bool get _nameValid =>
      Validators.isNonEmpty(_firstName.text) &&
      Validators.isNonEmpty(_lastName.text);

  bool get _dobValid => _dob != null && Validators.isAdult(_dob!);

  bool get _genderValid => _gender != null && _interestedIn.isNotEmpty;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
          maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (images.isEmpty) return;
      final limits = await ref.read(tierLimitsProvider.future);
      final maxPhotos = limits
          .firstWhere((t) => t.tier == 'basic',
              orElse: () => limits.first)
          .maxPhotos;
      setState(() {
        _pickedPhotos.addAll(images);
        while (_pickedPhotos.length > maxPhotos) {
          _pickedPhotos.removeLast();
        }
      });
      if (images.length + _pickedPhotos.length > maxPhotos) {
        showAppSnackbar(l10n.photoLimitReached);
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _saveProfileAndPhotos() async {
    final l10n = AppLocalizations.of(context);
    if (_pickedPhotos.length < AppConstants.minPhotos) {
      showAppSnackbar(l10n.photosMinRequired(AppConstants.minPhotos),
          isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      if (!_profileSaved) {
        await repo.createProfile(
          firstName: _firstName.text,
          lastName: _lastName.text,
          dateOfBirth: _dob!,
          gender: _gender!,
          interestedIn: _interestedIn.toList(),
          bio: _bio.text.isEmpty ? null : _bio.text,
        );
        _profileSaved = true;
      }
      final existing = await repo.fetchMyPhotos();
      var position = existing.length;
      for (final x in _pickedPhotos) {
        await repo.addPhoto(File(x.path), position: position++);
      }
      _goTo(4);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestLocation() async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showAppSnackbar(l10n.locationDenied, isError: true);
      } else {
        final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.medium));
        await ref
            .read(profileRepositoryProvider)
            .updateLocation(lat: pos.latitude, lng: pos.longitude);
      }
      _goTo(5);
    } catch (e) {
      if (mounted) showAppError(context, e);
      _goTo(5); // location is skippable; Nearby will re-ask
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      if (_bio.text.trim().isNotEmpty) {
        await ref
            .read(profileRepositoryProvider)
            .updateProfile({'bio': _bio.text.trim()});
      }
      // Refresh gate inputs → router redirects to /discover.
      await ref.read(myProfileProvider.notifier).reload();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        leading: _step > 0 && _step != 4
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goTo(_step - 1))
            : null,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_step + 1) / _steps,
                minHeight: 6,
                backgroundColor: AppColors.cyan50,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(l10n.stepOf(_step + 1, _steps),
                  style: AppTypography.caption),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _nameStep(l10n),
                  _dobStep(l10n),
                  _genderStep(l10n),
                  _photosStep(l10n),
                  _locationStep(l10n),
                  _bioStep(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrap({required List<Widget> children}) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children),
      );

  Widget _nameStep(AppLocalizations l10n) => _wrap(children: [
        Text(l10n.firstName, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _firstName,
          decoration: InputDecoration(labelText: l10n.firstName),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _lastName,
          decoration: InputDecoration(labelText: l10n.lastName),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
            label: l10n.continueLabel,
            onPressed: _nameValid ? () => _goTo(1) : null),
      ]);

  Widget _dobStep(AppLocalizations l10n) => _wrap(children: [
        Text(l10n.dateOfBirth, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: _pickDob,
          icon: const Icon(Icons.cake_outlined),
          label: Text(_dob == null
              ? l10n.dateOfBirth
              : '${_dob!.day.toString().padLeft(2, '0')}.${_dob!.month.toString().padLeft(2, '0')}.${_dob!.year}'),
        ),
        if (_dob != null && !_dobValid) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.mustBe18,
              style: AppTypography.body.copyWith(color: AppColors.error)),
        ],
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
            label: l10n.continueLabel,
            onPressed: _dobValid ? () => _goTo(2) : null),
      ]);

  Widget _genderStep(AppLocalizations l10n) {
    final options = {
      'male': l10n.genderMale,
      'female': l10n.genderFemale,
      'other': l10n.genderOther,
    };
    return _wrap(children: [
      Text(l10n.gender, style: AppTypography.h2),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final e in options.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: _gender == e.key,
              onSelected: (_) => setState(() => _gender = e.key),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(l10n.interestedIn, style: AppTypography.h2),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final e in options.entries)
            FilterChip(
              label: Text(e.value),
              selected: _interestedIn.contains(e.key),
              onSelected: (sel) => setState(() =>
                  sel ? _interestedIn.add(e.key) : _interestedIn.remove(e.key)),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      PrimaryButton(
          label: l10n.continueLabel,
          onPressed: _genderValid ? () => _goTo(3) : null),
    ]);
  }

  Widget _photosStep(AppLocalizations l10n) => _wrap(children: [
        Text(l10n.addPhotos, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.addPhotosHint(AppConstants.minPhotos),
            style:
                AppTypography.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.75),
          itemCount: _pickedPhotos.length + 1,
          itemBuilder: (context, i) {
            if (i == _pickedPhotos.length) {
              return Semantics(
                button: true,
                label: l10n.addPhoto,
                child: InkWell(
                  onTap: _busy ? null : _pickPhoto,
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cyan50,
                      borderRadius: BorderRadius.circular(AppSpacing.lg),
                      border: Border.all(color: AppColors.cyan100),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: AppColors.primaryDark),
                  ),
                ),
              );
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                  child:
                      Image.file(File(_pickedPhotos[i].path), fit: BoxFit.cover),
                ),
                if (i == 0)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(l10n.mainPhoto,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.onPrimary)),
                    ),
                  ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        minimumSize: const Size(32, 32)),
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () =>
                        setState(() => _pickedPhotos.removeAt(i)),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: l10n.continueLabel,
          loading: _busy,
          onPressed:
              _pickedPhotos.length >= AppConstants.minPhotos && !_busy
                  ? _saveProfileAndPhotos
                  : null,
        ),
      ]);

  Widget _locationStep(AppLocalizations l10n) => _wrap(children: [
        const SizedBox(height: AppSpacing.xxl),
        const Icon(Icons.near_me, size: 72, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.locationPermissionTitle,
            style: AppTypography.h1, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.locationPermissionBody,
            style:
                AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
            label: l10n.enableLocation,
            loading: _busy,
            onPressed: _busy ? null : _requestLocation),
        const SizedBox(height: AppSpacing.md),
        TextButton(onPressed: () => _goTo(5), child: Text(l10n.skip)),
      ]);

  Widget _bioStep(AppLocalizations l10n) => _wrap(children: [
        Text(l10n.bioLabel, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _bio,
          maxLines: 5,
          maxLength: 300,
          decoration: InputDecoration(hintText: l10n.bioHint),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
            label: l10n.done, loading: _busy, onPressed: _busy ? null : _finish),
      ]);
}
