import 'package:mime/mime.dart';

/// Mixin that provides HTTP-related helpers.
mixin HttpMixin {
  /// Guess the MIME type for [filename].
  /// Falls back to `application/octet-stream` if unknown.
  String contentType(String filename) {
    return lookupMimeType(filename) ?? "application/octet-stream";
  }

  /// JSON content-type constant (replaces `Headers.jsonContentType` from dio).
  static const String jsonContentType = "application/json";
}
