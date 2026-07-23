import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../auth/presentation/session_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _bio;
  String? _gender;
  late final Set<String> _interestedIn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(myProfileProvider).valueOrNull;
    _firstName = TextEditingController(text: profile?.firstName ?? '');
    _lastName = TextEditingController(text: profile?.lastName ?? '');
    _bio = TextEditingController(text: profile?.bio ?? '');
    _gender = profile?.gender;
    _interestedIn = {...profile?.interestedIn ?? const []};
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile({
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'gender': _gender,
        'interested_in': _interestedIn.toList(),
      });
      await ref.read(myProfileProvider.notifier).reload();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = {
      'male': l10n.genderMale,
      'female': l10n.genderFemale,
      'other': l10n.genderOther,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              TextFormField(
                controller: _firstName,
                decoration: InputDecoration(labelText: l10n.firstName),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    Validators.isNonEmpty(v) ? null : l10n.fieldRequired,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _lastName,
                decoration: InputDecoration(labelText: l10n.lastName),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    Validators.isNonEmpty(v) ? null : l10n.fieldRequired,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.gender, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
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
              Text(l10n.interestedIn, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final e in options.entries)
                    FilterChip(
                      label: Text(e.value),
                      selected: _interestedIn.contains(e.key),
                      onSelected: (sel) => setState(() => sel
                          ? _interestedIn.add(e.key)
                          : _interestedIn.remove(e.key)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _bio,
                maxLines: 5,
                maxLength: 300,
                decoration: InputDecoration(
                    labelText: l10n.bioLabel, hintText: l10n.bioHint),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                  label: l10n.save,
                  loading: _saving,
                  onPressed: _saving ? null : _save),
            ],
          ),
        ),
      ),
    );
  }
}
