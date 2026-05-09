/// Exception thrown when an OSS request fails.
class OssException implements Exception {
  const OssException({
    required this.message,
    this.statusCode,
    this.requestId,
    this.code,
  });

  /// Human-readable error message.
  final String message;

  /// HTTP status code, if available.
  final int? statusCode;

  /// OSS request ID for debugging.
  final String? requestId;

  /// OSS error code (e.g., "NoSuchKey", "AccessDenied").
  final String? code;

  factory OssException.fromStatus(int statusCode, {String? requestId, String? code, String? message}) {
    return OssException(
      message: message ?? 'HTTP $statusCode',
      statusCode: statusCode,
      requestId: requestId,
      code: code,
    );
  }

  @override
  String toString() {
    final parts = <String>[
      'OssException: $message',
      if (statusCode != null) 'statusCode=$statusCode',
      if (code != null) 'code=$code',
      if (requestId != null) 'requestId=$requestId',
    ];
    return parts.join(', ');
  }
}
