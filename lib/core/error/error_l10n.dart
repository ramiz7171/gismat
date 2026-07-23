import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import 'app_exception.dart';

/// Global messenger so any layer can surface a snackbar without a context
/// that is inside a Scaffold.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

extension AppErrorL10n on AppException {
  String localized(AppLocalizations l10n) => switch (code) {
        AppErrorCode.network => l10n.authNetworkError,
        AppErrorCode.wrongCredentials => l10n.authWrongCredentials,
        AppErrorCode.emailInUse => l10n.authEmailInUse,
        AppErrorCode.emailNotConfirmed => l10n.authEmailNotConfirmed,
        AppErrorCode.swipeLimitReached => l10n.limitReachedTitle,
        AppErrorCode.photoLimitReached => l10n.photoLimitReached,
        AppErrorCode.premiumRequired => l10n.rewindPremium,
        AppErrorCode.unknown => l10n.errorGeneric,
      };
}

void showAppError(BuildContext context, Object error) {
  final message = mapError(error).localized(AppLocalizations.of(context));
  showAppSnackbar(message, isError: true);
}

void showAppSnackbar(String message, {bool isError = false}) {
  rootScaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.textPrimary,
    ));
}
