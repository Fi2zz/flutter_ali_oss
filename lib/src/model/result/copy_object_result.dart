// 阿里云 OSS CopyObject API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/copyobject
//
// === 阿里云官方请求示例 ===
// PUT /dest.txt HTTP/1.1
// Host: bucket.oss-cn-zhangjiakou.aliyuncs.com
// x-oss-copy-source: /bucket/source.txt
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例（XML）===
// HTTP/1.1 200 OK
// Content-Type: application/xml
// x-oss-request-id: 5CAC0A3DB7AEADE01700****
//
// <CopyObjectResult>
//   <LastModified>Mon, 05 Jul 2021 10:09:13.000Z</LastModified>
//   <ETag>"D41D8CD98F00B204E9800998ECF8****"</ETag>
// </CopyObjectResult>
//
// === SDK 使用示例 ===
// ```dart
// final CopyObjectResult result = await client.copyObject(
//   CopyObjectRequest(
//     sourceKey: 'source.txt',
//     targetKey: 'dest.txt',
//     sourceBucketName: 'bucket',
//   ),
// );
// print(result.eTag);         // '"D41D8CD98F00B204E9800998ECF8****"'
// print(result.lastModified); // DateTime(2021, 7, 5, 10, 9, 13)
// ```

import 'package:xml/xml.dart';

/// Result of copying an object.
class CopyObjectResult {
  const CopyObjectResult({
    required this.eTag,
    required this.lastModified,
    this.versionId,
  });

  /// The ETag of the new object.
  /// XML path: CopyObjectResult/ETag
  final String eTag;

  /// The last modified time of the new object.
  /// XML path: CopyObjectResult/LastModified
  final DateTime lastModified;

  /// The version ID (when versioning is enabled).
  /// HTTP Header: x-oss-version-id
  final String? versionId;

  factory CopyObjectResult.fromXml(XmlDocument xml) {
    final root = xml.rootElement;
    return CopyObjectResult(
      eTag: root.getElement('ETag')?.innerText ?? '',
      lastModified: DateTime.tryParse(root.getElement('LastModified')?.innerText ?? '') ?? DateTime.now(),
    );
  }

  factory CopyObjectResult.fromResponse(int statusCode, Map<String, String> headers) {
    return CopyObjectResult(
      eTag: headers['etag'] ?? '',
      lastModified: DateTime.now(),
      versionId: headers['x-oss-version-id'],
    );
  }
}
