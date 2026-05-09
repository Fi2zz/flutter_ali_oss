import '../../client_api.dart';
import '../callback.dart';
import '../enums.dart';

/// Request parameters for uploading an object.
class PutObjectRequest {
  const PutObjectRequest({
    required this.key,
    required this.data,
    this.bucketName,
    this.aclMode,
    this.storageType,
    this.override,
    this.callback,
    this.headers,
    this.onSendProgress,
    this.onReceiveProgress,
  });

  /// The key (path/name) of the object.
  final String key;

  /// The binary data of the object.
  final List<int> data;

  /// The target bucket (uses default if not specified).
  final String? bucketName;

  /// The access control list for the object.
  final AclMode? aclMode;

  /// The storage class for the object.
  final StorageType? storageType;

  /// Whether to allow overwriting existing objects.
  final bool? override;

  /// Callback configuration after upload.
  final Callback? callback;

  /// Additional HTTP headers.
  final Map<String, dynamic>? headers;

  /// Progress callback for upload.
  final ProgressCallback? onSendProgress;

  /// Progress callback for receiving response.
  final ProgressCallback? onReceiveProgress;
}

/// Request parameters for uploading an object from a file.
class PutObjectFileRequest {
  const PutObjectFileRequest({
    required this.filepath,
    this.key,
    this.bucketName,
    this.aclMode,
    this.storageType,
    this.override,
    this.callback,
    this.headers,
    this.onSendProgress,
    this.onReceiveProgress,
  });

  /// The local file path to upload.
  final String filepath;

  /// The key (path/name) of the object (uses filename if not specified).
  final String? key;

  /// The target bucket (uses default if not specified).
  final String? bucketName;

  /// The access control list for the object.
  final AclMode? aclMode;

  /// The storage class for the object.
  final StorageType? storageType;

  /// Whether to allow overwriting existing objects.
  final bool? override;

  /// Callback configuration after upload.
  final Callback? callback;

  /// Additional HTTP headers.
  final Map<String, dynamic>? headers;

  /// Progress callback for upload.
  final ProgressCallback? onSendProgress;

  /// Progress callback for receiving response.
  final ProgressCallback? onReceiveProgress;
}
