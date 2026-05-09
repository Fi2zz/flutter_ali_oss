/// A token that can be used to cancel an in-flight HTTP request.
class CancelToken {
  bool _isCancelled = false;
  String? _reason;

  /// Whether the request has been cancelled.
  bool get isCancelled => _isCancelled;

  /// The reason for cancellation, if any.
  String? get reason => _reason;

  /// Cancel the request with an optional [reason].
  void cancel([String? reason]) {
    _isCancelled = true;
    _reason = reason;
  }

  /// Throw a [CancelException] if this token has been cancelled.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancelException(reason ?? 'Request cancelled');
    }
  }
}

/// Exception thrown when a request is cancelled via a [CancelToken].
class CancelException implements Exception {
  const CancelException(this.message);

  final String message;

  @override
  String toString() => 'CancelException: $message';
}
