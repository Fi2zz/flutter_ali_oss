// 阿里云 OSS PutObject API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/putobject
//
// === 阿里云官方请求示例 ===
// PUT /test.txt HTTP/1.1
// Host: bucket.oss-cn-zhangjiakou.aliyuncs.com
// Content-Length: 4
// Authorization: OSS4-HMAC-SHA256 ...
//
// Test
//
// === 阿里云官方响应示例（HTTP Headers）===
// HTTP/1.1 200 OK
// Server: AliyunOSS
// Date: Wed, 11 Sep 2024 02:47:53 GMT
// Content-Length: 0
// Connection: keep-alive
// x-oss-request-id: 66E0F379B8DB39393911****
// ETag: "D41D8CD98F00B204E9800998ECF8****"
// x-oss-hash-crc64ecma: 5981763651835930
// x-oss-version-id: CAEQNRiBgIDMh4mD0BYiIDUzNDA4OGNmZjBjYTQ0YmI4Y2I4ZmVlYzJlNGVk****
//
// === SDK 使用示例 ===
// ```dart
// final PutObjectResult result = await client.putObject(
//   PutObjectRequest(
//     key: 'test.txt',
//     data: utf8.encode('Test'),
//     aclMode: AclMode.private,
//     storageType: StorageType.standard,
//   ),
// );
// print(result.eTag);        // '"D41D8CD98F00B204E9800998ECF8****"'
// print(result.statusCode);  // 200
// print(result.hashCrc64);   // '5981763651835930'
// print(result.versionId);   // 'CAEQNRiBgIDMh4mD0BYiIDUzNDA4OGNmZjBjYTQ0YmI4Y2I4ZmVlYzJlNGVk****'
// ```

import '../../util/oss_response.dart';

/// Result of uploading an object.
class PutObjectResult {
  const PutObjectResult({
    required this.eTag,
    required this.statusCode,
    this.versionId,
    this.hashCrc64,
    this.callbackResult,
  });

  /// The ETag of the uploaded object.
  /// HTTP Header: ETag
  final String eTag;

  /// The HTTP status code.
  final int statusCode;

  /// The version ID (when versioning is enabled).
  /// HTTP Header: x-oss-version-id
  final String? versionId;

  /// The CRC64 hash.
  /// HTTP Header: x-oss-hash-crc64ecma
  final String? hashCrc64;

  /// The callback result (if callback was configured).
  final Map<String, dynamic>? callbackResult;

  factory PutObjectResult.fromOssResponse(StringResponse response) {
    final h = response.headers;
    return PutObjectResult(
      eTag: h['etag'] ?? '',
      statusCode: response.statusCode,
      versionId: h['x-oss-version-id'],
      hashCrc64: h['x-oss-hash-crc64ecma'],
      callbackResult: null,
    );
  }
}
