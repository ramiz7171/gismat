import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/admin/presentation/admin_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/session_providers.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/discovery/presentation/discovery_screen.dart';
import '../../features/discovery/presentation/user_detail_screen.dart';
import '../../features/matches/presentation/chats_screen.dart';
import '../../features/nearby/presentation/nearby_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/poke/presentation/pokes_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/my_profile_screen.dart';
import '../../features/profile/presentation/verification_screen.dart';
import '../../features/settings/presentation/blocked_users_screen.dart';
import '../../features/settings/presentation/legal_screens.dart';
import '../../features/settings/presentation/safety_center_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../widgets/home_shell.dart';
import 'routes.dart';

part 'app_router.g.dart';

const _publicPaths = {
  Routes.welcome,
  Routes.signIn,
  Routes.register,
  Routes.forgotPassword,
  Routes.terms,
  Routes.privacy,
};

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(authGateProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final gate = ref.read(authGateProvider);
      final path = state.matchedLocation;
      final isPublic = _publicPaths.contains(path);

      final status = gate.valueOrNull;
      if (status == null) {
        // still resolving (or errored → splash retries)
        return path == Routes.splash ? null : Routes.splash;
      }
      switch (status) {
        case GateStatus.loading:
          return path == Routes.splash ? null : Routes.splash;
        case GateStatus.unauthenticated:
          return isPublic ? null : Routes.welcome;
        case GateStatus.needsOnboarding:
          if (path == Routes.onboarding || path == Routes.terms || path == Routes.privacy) {
            return null;
          }
          return Routes.onboarding;
        case GateStatus.ready:
          if (path == Routes.splash ||
              path == Routes.onboarding ||
              isPublic && path != Routes.terms && path != Routes.privacy) {
            return Routes.discover;
          }
          return null;
      }
      // ignore: dead_code
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
          path: Routes.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
          path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.discover,
                builder: (_, _) => const DiscoveryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.nearby, builder: (_, _) => const NearbyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.chats, builder: (_, _) => const ChatsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.me, builder: (_, _) => const MyProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) =>
            ChatScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (_, state) =>
            UserDetailScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.pokes, builder: (_, _) => const PokesScreen()),
      GoRoute(
          path: Routes.notifications,
          builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: Routes.paywall, builder: (_, _) => const PaywallScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(
          path: Routes.blockedUsers,
          builder: (_, _) => const BlockedUsersScreen()),
      GoRoute(
          path: Routes.safety, builder: (_, _) => const SafetyCenterScreen()),
      GoRoute(path: Routes.terms, builder: (_, _) => const TermsScreen()),
      GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(
          path: Routes.verify, builder: (_, _) => const VerificationScreen()),
      GoRoute(
          path: Routes.editProfile,
          builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: Routes.admin, builder: (_, _) => const AdminScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
