import 'dart:async';

import 'model/auth.dart';

/// Mixin that manages authentication state and token refresh.
mixin AuthMixin {
  /// The user-provided authenticator that returns fresh [Auth] credentials.
  late FutureOr<Auth> Function() authenticator;

  Auth? _auth;

  /// Cached authentication credentials.
  Auth? get auth => _auth;

  /// Get valid auth credentials, refreshing if necessary.
  Future<Auth> getAuth() async {
    if (isUnauthenticated) {
      _auth = await authenticator();
      return _auth!;
    }
    return _auth!;
  }

  /// Whether the current auth is missing or expired.
  bool get isUnauthenticated {
    return _auth == null || _auth!.isExpired;
  }

  /// Force a re-authentication on the next request.
  void clearAuth() => _auth = null;
}
