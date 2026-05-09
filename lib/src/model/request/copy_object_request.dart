import '../enums.dart';

/// Request parameters for copying an object.
class CopyObjectRequest {
  const CopyObjectRequest({
    required this.sourceKey,
    this.sourceBucketName,
    required this.targetKey,
    this.targetBucketName,
    this.aclMode,
    this.storageType,
    this.override,
    this.headers,
  });

  /// The source object key to copy from.
  final String sourceKey;

  /// The source bucket (uses default if not specified).
  final String? sourceBucketName;

  /// The target object key to copy to.
  final String targetKey;

  /// The target bucket (uses source bucket if not specified).
  final String? targetBucketName;

  /// The access control list for the new object.
  final AclMode? aclMode;

  /// The storage class for the new object.
  final StorageType? storageType;

  /// Whether to allow overwriting existing objects.
  final bool? override;

  /// Additional HTTP headers.
  final Map<String, dynamic>? headers;
}
