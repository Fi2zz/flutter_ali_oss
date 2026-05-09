/// Request parameters for getting an object.
class GetObjectRequest {
  const GetObjectRequest({
    required this.key,
    this.bucketName,
    this.range,
    this.ifMatch,
    this.ifNoneMatch,
    this.ifModifiedSince,
    this.ifUnmodifiedSince,
    this.responseContentType,
    this.responseContentDisposition,
    this.responseCacheControl,
  });

  /// The key of the object to get.
  final String key;

  /// The target bucket (uses default if not specified).
  final String? bucketName;

  /// The range of bytes to retrieve (e.g., "bytes=0-999").
  final String? range;

  /// Return the object only if its ETag matches this value.
  final String? ifMatch;

  /// Return the object only if its ETag does not match this value.
  final String? ifNoneMatch;

  /// Return the object only if it has been modified since this time.
  final DateTime? ifModifiedSince;

  /// Return the object only if it has not been modified since this time.
  final DateTime? ifUnmodifiedSince;

  /// Overrides the Content-Type header in the response.
  final String? responseContentType;

  /// Overrides the Content-Disposition header in the response.
  final String? responseContentDisposition;

  /// Overrides the Cache-Control header in the response.
  final String? responseCacheControl;

  /// Converts to HTTP headers for the request.
  Map<String, dynamic> toHeaders() {
    return {
      if (range != null) 'Range': range,
      if (ifMatch != null) 'If-Match': ifMatch,
      if (ifNoneMatch != null) 'If-None-Match': ifNoneMatch,
      if (ifModifiedSince != null)
        'If-Modified-Since': ifModifiedSince!.toUtc().toIso8601String(),
      if (ifUnmodifiedSince != null)
        'If-Unmodified-Since': ifUnmodifiedSince!.toUtc().toIso8601String(),
    };
  }

  /// Converts to query parameters for the request.
  Map<String, dynamic> toParameters() {
    return {
      if (responseContentType != null) 'response-content-type': responseContentType,
      if (responseContentDisposition != null)
        'response-content-disposition': responseContentDisposition,
      if (responseCacheControl != null) 'response-cache-control': responseCacheControl,
    };
  }
}
