/// Request parameters for listing all buckets.
class ListBucketsRequest {
  const ListBucketsRequest({
    this.prefix,
    this.marker,
    this.maxKeys,
  });

  /// Filter results to buckets that begin with this prefix.
  final String? prefix;

  /// The marker to use for pagination.
  final String? marker;

  /// The maximum number of buckets to return.
  final int? maxKeys;

  /// Converts to query parameters for the API request.
  Map<String, dynamic> toParameters() {
    return {
      if (prefix != null) 'prefix': prefix,
      if (marker != null) 'marker': marker,
      if (maxKeys != null) 'max-keys': maxKeys.toString(),
    };
  }
}
