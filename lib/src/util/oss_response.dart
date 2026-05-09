/// A typed HTTP response from OSS.
class OssResponse<T> {
  const OssResponse({
    required this.data,
    required this.statusCode,
    this.headers = const {},
    this.requestId,
  });

  /// The response body data.
  final T data;

  /// The HTTP status code.
  final int statusCode;

  /// All HTTP response headers (keys are lower-cased).
  final Map<String, String> headers;

  /// The OSS request ID from the x-oss-request-id header.
  final String? requestId;

  /// Whether the response status indicates success (2xx).
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// Convenience accessor for a single header value.
  String? header(String name) => headers[name.toLowerCase()];
}

/// Raw bytes response — used when the body is binary (e.g. file download).
typedef BytesResponse = OssResponse<List<int>>;

/// String response — used for XML/text responses.
typedef StringResponse = OssResponse<String>;

/// Empty response — used for operations that return no body (e.g. DELETE).
typedef EmptyResponse = OssResponse<void>;
