import '../../client_api.dart';
import '../enums.dart';
import 'put_object_request.dart';

typedef MultipartPartProgressCallback = void Function(
  int partNumber,
  int count,
  int total,
);

typedef MultipartBatchUploadProgressCallback = void Function(
  int completed,
  int total,
);

enum UploadMode {
  simple,
  multipart,
}

class InitiateMultipartUploadRequest {
  const InitiateMultipartUploadRequest({
    required this.key,
    this.bucketName,
    this.aclMode,
    this.storageType,
    this.override,
    this.headers,
    this.encodingType,
  });

  final String key;
  final String? bucketName;
  final AclMode? aclMode;
  final StorageType? storageType;
  final bool? override;
  final Map<String, dynamic>? headers;
  final String? encodingType;
}

class UploadPartRequest {
  const UploadPartRequest({
    required this.key,
    required this.uploadId,
    required this.partNumber,
    required this.data,
    this.bucketName,
    this.headers,
    this.onSendProgress,
  });

  final String key;
  final String uploadId;
  final int partNumber;
  final List<int> data;
  final String? bucketName;
  final Map<String, dynamic>? headers;
  final ProgressCallback? onSendProgress;
}

class UploadedPart {
  const UploadedPart({
    required this.partNumber,
    required this.eTag,
    this.size,
  });

  final int partNumber;
  final String eTag;
  final int? size;
}

class CompleteMultipartUploadRequest {
  const CompleteMultipartUploadRequest({
    required this.key,
    required this.uploadId,
    required this.parts,
    this.bucketName,
    this.override,
    this.aclMode,
    this.headers,
    this.encodingType,
  });

  final String key;
  final String uploadId;
  final List<UploadedPart> parts;
  final String? bucketName;
  final bool? override;
  final AclMode? aclMode;
  final Map<String, dynamic>? headers;
  final String? encodingType;
}

class MultipartUploadFileRequest {
  const MultipartUploadFileRequest({
    required this.filepath,
    this.key,
    this.bucketName,
    this.partSize = 8 * 1024 * 1024,
    this.parallel = 3,
    this.aclMode,
    this.storageType,
    this.override,
    this.headers,
    this.onSendProgress,
    this.onPartProgress,
    this.resumable = false,
    this.checkpointDir,
    this.checkpointKey,
  });

  final String filepath;
  final String? key;
  final String? bucketName;
  final int partSize;
  final int parallel;
  final AclMode? aclMode;
  final StorageType? storageType;
  final bool? override;
  final Map<String, dynamic>? headers;
  final ProgressCallback? onSendProgress;
  final MultipartPartProgressCallback? onPartProgress;
  final bool resumable;
  final String? checkpointDir;
  final String? checkpointKey;
}

class MultipartUploadFilesRequest {
  const MultipartUploadFilesRequest({
    required this.files,
    this.parallel = 3,
    this.onProgress,
  });

  final List<MultipartUploadFileRequest> files;
  final int parallel;
  final MultipartBatchUploadProgressCallback? onProgress;
}

class ListMultipartUploadsRequest {
  const ListMultipartUploadsRequest({
    this.bucketName,
    this.prefix,
    this.delimiter,
    this.keyMarker,
    this.uploadIdMarker,
    this.maxUploads,
    this.encodingType,
  });

  final String? bucketName;
  final String? prefix;
  final String? delimiter;
  final String? keyMarker;
  final String? uploadIdMarker;
  final int? maxUploads;
  final String? encodingType;
}

class ListPartsRequest {
  const ListPartsRequest({
    required this.key,
    required this.uploadId,
    this.bucketName,
    this.maxParts,
    this.partNumberMarker,
    this.encodingType,
  });

  final String key;
  final String uploadId;
  final String? bucketName;
  final int? maxParts;
  final int? partNumberMarker;
  final String? encodingType;
}

class UploadFileRequest {
  const UploadFileRequest({
    required this.filepath,
    this.key,
    this.bucketName,
    this.multipartThreshold = 100 * 1024 * 1024,
    this.partSize = 8 * 1024 * 1024,
    this.parallel = 3,
    this.aclMode,
    this.storageType,
    this.override,
    this.headers,
    this.onSendProgress,
    this.onPartProgress,
    this.resumable = false,
    this.checkpointDir,
    this.checkpointKey,
  });

  final String filepath;
  final String? key;
  final String? bucketName;
  final int multipartThreshold;
  final int partSize;
  final int parallel;
  final AclMode? aclMode;
  final StorageType? storageType;
  final bool? override;
  final Map<String, dynamic>? headers;
  final ProgressCallback? onSendProgress;
  final MultipartPartProgressCallback? onPartProgress;
  final bool resumable;
  final String? checkpointDir;
  final String? checkpointKey;

  UploadMode modeFor(int size) {
    if (size < multipartThreshold) return UploadMode.simple;
    return UploadMode.multipart;
  }

  PutObjectFileRequest toPutRequest() {
    return PutObjectFileRequest(
      filepath: filepath,
      key: key,
      bucketName: bucketName,
      aclMode: aclMode,
      storageType: storageType,
      override: override,
      headers: headers,
      onSendProgress: onSendProgress,
    );
  }

  MultipartUploadFileRequest toMultipartRequest() {
    return MultipartUploadFileRequest(
      filepath: filepath,
      key: key,
      bucketName: bucketName,
      partSize: partSize,
      parallel: parallel,
      aclMode: aclMode,
      storageType: storageType,
      override: override,
      headers: headers,
      onSendProgress: onSendProgress,
      onPartProgress: onPartProgress,
      resumable: resumable,
      checkpointDir: checkpointDir,
      checkpointKey: checkpointKey,
    );
  }
}

class UploadFilesRequest {
  const UploadFilesRequest({
    required this.files,
    this.parallel = 3,
    this.onProgress,
  });

  final List<UploadFileRequest> files;
  final int parallel;
  final MultipartBatchUploadProgressCallback? onProgress;
}
