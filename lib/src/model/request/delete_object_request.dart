/// Request parameters for deleting an object.
class DeleteObjectRequest {
  const DeleteObjectRequest({
    required this.key,
    this.bucketName,
    this.versionId,
  });

  /// The key of the object to delete.
  final String key;

  /// The target bucket (uses default if not specified).
  final String? bucketName;

  /// The version ID of the object to delete (for versioned buckets).
  final String? versionId;
}

/// Request parameters for deleting multiple objects.
class DeleteObjectsRequest {
  const DeleteObjectsRequest({
    required this.keys,
    this.bucketName,
    this.quiet = false,
  });

  /// The list of object keys to delete.
  final List<String> keys;

  /// The target bucket (uses default if not specified).
  final String? bucketName;

  /// If true, only errors will be returned in the response.
  final bool quiet;
}
