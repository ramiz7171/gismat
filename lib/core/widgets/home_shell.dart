import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/presentation/notification_providers.dart';
import '../l10n/generated/app_localizations.dart';
import '../router/routes.dart';
import '../theme/app_colors.dart';

/// Bottom-nav scaffold hosting the four main branches.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: shell,
      appBar: AppBar(
        title: Text(l10n.appName,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.primaryDark)),
        actions: [
          IconButton(
            tooltip: l10n.pokesTitle,
            onPressed: () => context.push(Routes.pokes),
            icon: const Icon(Icons.front_hand_outlined, color: AppColors.poke),
          ),
          IconButton(
            tooltip: l10n.notificationsTitle,
            onPressed: () => context.push(Routes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.cyan50,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.style_outlined),
              selectedIcon: const Icon(Icons.style, color: AppColors.primaryDark),
              label: l10n.navDiscover),
          NavigationDestination(
              icon: const Icon(Icons.near_me_outlined),
              selectedIcon:
                  const Icon(Icons.near_me, color: AppColors.primaryDark),
              label: l10n.navNearby),
          NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon:
                  const Icon(Icons.chat_bubble, color: AppColors.primaryDark),
              label: l10n.navChats),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon:
                  const Icon(Icons.person, color: AppColors.primaryDark),
              label: l10n.navProfile),
        ],
      ),
    );
  }
}
