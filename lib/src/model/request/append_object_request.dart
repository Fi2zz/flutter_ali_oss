import '../../client_api.dart';
import '../enums.dart';

/// Request parameters for appending data to an object.
class AppendObjectRequest {
  const AppendObjectRequest({
    required this.key,
    required this.data,
    this.position,
    this.bucketName,
    this.aclMode,
    this.storageType,
    this.headers,
    this.onSendProgress,
    this.onReceiveProgress,
  });

  /// The key (path/name) of the object.
  final String key;

  /// The binary data to append.
  final List<int> data;

  /// The position to append from (0 for new object, use nextPosition from previous append).
  final int? position;

  /// The target bucket (uses default if not specified).
  final String? bucketName;

  /// The access control list for the object.
  final AclMode? aclMode;

  /// The storage class for the object.
  final StorageType? storageType;

  /// Additional HTTP headers.
  final Map<String, dynamic>? headers;

  /// Progress callback for upload.
  final ProgressCallback? onSendProgress;

  /// Progress callback for receiving response.
  final ProgressCallback? onReceiveProgress;
}
