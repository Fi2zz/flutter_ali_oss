// 阿里云 OSS DeleteObject API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/deleteobject
//
// === 阿里云官方请求示例 ===
// DELETE /test.txt HTTP/1.1
// Host: bucket.oss-cn-zhangjiakou.aliyuncs.com
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例 ===
// HTTP/1.1 204 No Content
// Server: AliyunOSS
// Date: Wed, 11 Sep 2024 02:47:53 GMT
// x-oss-request-id: 66E0F379B8DB39393911****
//
// === SDK 使用示例 ===
// ```dart
// final DeleteObjectResult result = await client.deleteObject('test.txt');
// print(result.deleted);    // true
// print(result.statusCode); // 204
// print(result.key);        // 'test.txt'
// ```

/// Result of deleting an object.
class DeleteObjectResult {
  const DeleteObjectResult({
    required this.key,
    required this.deleted,
    required this.statusCode,
    this.versionId,
    this.deleteMarker,
    this.deleteMarkerVersionId,
  });

  /// The key of the deleted object.
  final String key;

  /// Whether the deletion was successful.
  final bool deleted;

  /// The HTTP status code.
  final int statusCode;

  /// The version ID of the deleted object (versioned buckets).
  final String? versionId;

  /// Whether a delete marker was created.
  final bool? deleteMarker;

  /// The version ID of the delete marker.
  final String? deleteMarkerVersionId;

  factory DeleteObjectResult.fromResponse(String key, int statusCode) {
    return DeleteObjectResult(
      key: key,
      deleted: statusCode == 204 || statusCode == 200,
      statusCode: statusCode,
    );
  }
}
