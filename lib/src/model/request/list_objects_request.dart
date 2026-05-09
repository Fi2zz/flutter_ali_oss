/// Request parameters for listing objects in a bucket (ListObjectsV2).
class ListObjectsRequest {
  const ListObjectsRequest({
    this.prefix,
    this.delimiter,
    this.maxKeys = 100,
    this.startAfter,
    this.continuationToken,
    this.encodingType,
    this.fetchOwner = false,
  });

  /// Filter results to keys that begin with this prefix.
  final String? prefix;

  /// A delimiter is a character you use to group keys.
  final String? delimiter;

  /// Sets the maximum number of keys returned in the response body.
  /// Range: 1-1000, default: 100
  final int maxKeys;

  /// Return keys alphabetically after this key.
  final String? startAfter;

  /// Used for pagination - token from previous ListObjectsResult.nextContinuationToken.
  final String? continuationToken;

  /// Request OSS to encode the response and specify the encoding type.
  final String? encodingType;

  /// Whether to include owner information in the response.
  final bool fetchOwner;

  /// Converts to query parameters for the API request.
  Map<String, dynamic> toParameters() {
    return {
      'list-type': '2',
      if (prefix != null) 'prefix': prefix,
      if (delimiter != null) 'delimiter': delimiter,
      'max-keys': maxKeys.toString(),
      if (startAfter != null) 'start-after': startAfter,
      if (continuationToken != null) 'continuation-token': continuationToken,
      if (encodingType != null) 'encoding-type': encodingType,
      if (fetchOwner) 'fetch-owner': 'true',
    };
  }
}
