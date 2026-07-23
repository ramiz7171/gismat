import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Stable error identities the UI can localize.
enum AppErrorCode {
  network,
  wrongCredentials,
  emailInUse,
  emailNotConfirmed,
  swipeLimitReached,
  photoLimitReached,
  premiumRequired,
  unknown,
}

class AppException implements Exception {
  const AppException(this.code, [this.debugMessage]);

  final AppErrorCode code;
  final String? debugMessage;

  @override
  String toString() => 'AppException($code, $debugMessage)';
}

/// Maps raw Supabase/socket errors to [AppException] so the presentation
/// layer never has to know about backend exception types.
AppException mapError(Object error) {
  if (error is AppException) return error;
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return const AppException(AppErrorCode.wrongCredentials);
    }
    if (msg.contains('already registered') || error.code == 'user_already_exists') {
      return const AppException(AppErrorCode.emailInUse);
    }
    if (msg.contains('email not confirmed')) {
      return const AppException(AppErrorCode.emailNotConfirmed);
    }
    return AppException(AppErrorCode.unknown, error.message);
  }
  if (error is PostgrestException) {
    return switch (error.code) {
      'P0001' => const AppException(AppErrorCode.swipeLimitReached),
      'P0002' => const AppException(AppErrorCode.photoLimitReached),
      'P0003' => const AppException(AppErrorCode.premiumRequired),
      _ => AppException(AppErrorCode.unknown, error.message),
    };
  }
  if (error is StorageException) {
    return AppException(AppErrorCode.unknown, error.message);
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return const AppException(AppErrorCode.network);
  }
  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection')) {
    return const AppException(AppErrorCode.network);
  }
  return AppException(AppErrorCode.unknown, error.toString());
}
