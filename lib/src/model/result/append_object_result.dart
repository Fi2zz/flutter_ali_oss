// 阿里云 OSS AppendObject API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/appendobject
//
// === 阿里云官方请求示例 ===
// POST /append.txt?append&position=0 HTTP/1.1
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
// x-oss-next-append-position: 4
// x-oss-hash-crc64ecma: 5981763651835930
//
// === SDK 使用示例 ===
// ```dart
// // First append at position 0
// final AppendObjectResult r1 = await client.appendObject(
//   AppendObjectRequest(
//     key: 'append.txt',
//     data: utf8.encode('Test'),
//     position: 0,
//   ),
// );
// print(r1.nextPosition);  // 4 (next append starts here)
// print(r1.eTag);          // '"D41D8CD98F00B204E9800998ECF8****"'
//
// // Continue appending at position 4
// final AppendObjectResult r2 = await client.appendObject(
//   AppendObjectRequest(
//     key: 'append.txt',
//     data: utf8.encode('More'),
//     position: r1.nextPosition,
//   ),
// );
// print(r2.nextPosition);  // 8
// ```

import '../../util/oss_response.dart';

/// Result of appending to an object.
class AppendObjectResult {
  const AppendObjectResult({
    required this.nextPosition,
    required this.statusCode,
    this.eTag,
    this.hashCrc64,
    this.versionId,
  });

  /// The next position for subsequent append operations.
  /// HTTP Header: x-oss-next-append-position
  final int nextPosition;

  /// The HTTP status code.
  final int statusCode;

  /// The ETag of the appended content.
  /// HTTP Header: ETag
  final String? eTag;

  /// The CRC64 hash.
  /// HTTP Header: x-oss-hash-crc64ecma
  final String? hashCrc64;

  /// The version ID (when versioning is enabled).
  /// HTTP Header: x-oss-version-id
  final String? versionId;

  factory AppendObjectResult.fromOssResponse(StringResponse response) {
    final h = response.headers;
    return AppendObjectResult(
      nextPosition: int.tryParse(h['x-oss-next-append-position'] ?? '0') ?? 0,
      statusCode: response.statusCode,
      eTag: h['etag'],
      hashCrc64: h['x-oss-hash-crc64ecma'],
      versionId: h['x-oss-version-id'],
    );
  }
}
