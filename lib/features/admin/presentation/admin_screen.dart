import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_providers.dart';
import '../../profile/domain/profile.dart';
import 'admin_providers.dart';

/// Admin console: users / reports / verifications / stats.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider).valueOrNull;
    if (profile == null || !profile.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminTitle)),
        body: EmptyState(icon: Icons.lock_outline, title: l10n.errorGeneric),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.adminUsers),
              Tab(text: l10n.adminReports),
              Tab(text: l10n.adminVerifications),
              Tab(text: l10n.adminStats),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(l10n),
            _buildReportsTab(l10n),
            _buildVerificationsTab(l10n),
            _buildStatsTab(l10n),
          ],
        ),
      ),
    );
  }

  // ---- Users -----------------------------------------------------------

  Widget _buildUsersTab(AppLocalizations l10n) {
    final results = ref.watch(adminUserSearchProvider(_query));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.adminSearchUsers,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: results.when(
            loading: () => _skeletonList(),
            error: (e, _) => _errorList(l10n),
            data: (users) => RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(adminUserSearchProvider(_query).future),
              child: users.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EmptyState(
                            icon: Icons.person_search,
                            title: l10n.adminUsers),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      itemCount: users.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, index) =>
                          _userRow(l10n, users[index]),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _userRow(AppLocalizations l10n, Profile user) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const VerifiedBadge(size: 16),
                    ],
                    if (user.isBanned) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.block,
                          size: 16, color: AppColors.error),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cyan50,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    user.tier,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.primaryDarker),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor:
                  user.isBanned ? AppColors.success : AppColors.error,
            ),
            onPressed: () => _toggleBan(user),
            child: Text(user.isBanned ? l10n.adminUnban : l10n.adminBan),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBan(Profile user) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setBanned(user.id, !user.isBanned);
      ref.invalidate(adminUserSearchProvider);
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  // ---- Reports ---------------------------------------------------------

  Widget _buildReportsTab(AppLocalizations l10n) {
    final reports = ref.watch(adminReportsProvider);
    return reports.when(
      loading: () => _skeletonList(),
      error: (e, _) => _errorList(l10n),
      data: (items) => RefreshIndicator(
        onRefresh: () => ref.refresh(adminReportsProvider.future),
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyState(
                      icon: Icons.flag_outlined, title: l10n.adminNoReports),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _reportCard(l10n, items[index]),
              ),
      ),
    );
  }

  String _personName(Object? raw) {
    if (raw is! Map) return '—';
    final first = raw['first_name'] as String? ?? '';
    final last = raw['last_name'] as String? ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? '—' : name;
  }

  Widget _reportCard(AppLocalizations l10n, Map<String, dynamic> report) {
    final details = (report['details'] as String?)?.trim();
    final createdAt = DateTime.tryParse(report['created_at'] as String? ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(_personName(report['reporter']),
                    style: AppTypography.body,
                    overflow: TextOverflow.ellipsis),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.textSecondary),
              ),
              Flexible(
                child: Text(_personName(report['reported']),
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report['reason'] as String? ?? '—',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(details,
                style: AppTypography.body
                    .copyWith(color: AppColors.textSecondary)),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(timeago.format(createdAt), style: AppTypography.caption),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
                onPressed: () =>
                    _resolveReport(report['id'] as String, 'dismissed'),
                child: Text(l10n.adminReject),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () =>
                    _resolveReport(report['id'] as String, 'actioned'),
                child: Text(l10n.adminApprove),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolveReport(String reportId, String status) async {
    try {
      await ref.read(adminRepositoryProvider).setReportStatus(reportId, status);
      ref.invalidate(adminReportsProvider);
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  // ---- Verifications ---------------------------------------------------

  Widget _buildVerificationsTab(AppLocalizations l10n) {
    final verifications = ref.watch(adminVerificationsProvider);
    return verifications.when(
      loading: () => _skeletonList(),
      error: (e, _) => _errorList(l10n),
      data: (items) => RefreshIndicator(
        onRefresh: () => ref.refresh(adminVerificationsProvider.future),
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyState(
                      icon: Icons.verified_outlined,
                      title: l10n.adminNoVerifications),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _verificationCard(l10n, items[index]),
              ),
      ),
    );
  }

  Widget _verificationCard(AppLocalizations l10n, Map<String, dynamic> row) {
    final userId = row['id'] as String;
    final name =
        '${row['first_name'] as String? ?? ''} ${row['last_name'] as String? ?? ''}'
            .trim();
    final path = row['verification_photo_path'] as String?;
    final url = path == null
        ? null
        : ref
            .read(supabaseClientProvider)
            .storage
            .from('profile-photos')
            .getPublicUrl(path);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const Skeleton(height: double.infinity, radius: 0),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.cyan100,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.primaryDark, size: 40),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(name.isEmpty ? '—' : name, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () => _resolveVerification(userId, approve: false),
                child: Text(l10n.adminReject),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.success),
                onPressed: () => _resolveVerification(userId, approve: true),
                child: Text(l10n.adminApprove),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolveVerification(String userId,
      {required bool approve}) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .resolveVerification(userId, approve: approve);
      ref.invalidate(adminVerificationsProvider);
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  // ---- Stats -----------------------------------------------------------

  Widget _buildStatsTab(AppLocalizations l10n) {
    final stats = ref.watch(adminStatsProvider);
    return stats.when(
      loading: () => _skeletonList(),
      error: (e, _) => _errorList(l10n),
      data: (counts) => RefreshIndicator(
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: GridView.count(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 1.2,
          children: [
            _statCard('${counts['users'] ?? 0}', l10n.adminUsers),
            _statCard('${counts['matches'] ?? 0}', l10n.matchesTitle),
            _statCard('${counts['messages'] ?? 0}', l10n.navChats),
            _statCard('${counts['openReports'] ?? 0}', l10n.adminReports),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String caption) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(child: Text(value, style: AppTypography.display)),
          const SizedBox(height: AppSpacing.xs),
          Text(caption,
              style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ---- Shared ----------------------------------------------------------

  Widget _skeletonList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 6,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Skeleton(height: 64, radius: AppRadius.button),
      ),
    );
  }

  Widget _errorList(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.error_outline,
      title: l10n.errorLoadFailed,
      actionLabel: l10n.retry,
      onAction: () {
        ref.invalidate(adminUserSearchProvider);
        ref.invalidate(adminReportsProvider);
        ref.invalidate(adminVerificationsProvider);
        ref.invalidate(adminStatsProvider);
      },
    );
  }
}
