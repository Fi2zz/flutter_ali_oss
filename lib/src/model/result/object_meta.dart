// 阿里云 OSS GetObjectMeta / HeadObject API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/getobjectmeta
//
// === 阿里云官方请求示例 ===
// HEAD /oss.jpg?objectMeta HTTP/1.1
// Host: oss-example.oss-cn-hangzhou.aliyuncs.com
// Date: Wed, 29 Apr 2015 05:21:12 GMT
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例（HTTP Headers）===
// HTTP/1.1 200 OK
// x-oss-request-id: 559CC9BDC755F95A6448****
// Date: Wed, 29 Apr 2015 05:21:12 GMT
// ETag: "5B3C1A2E053D763E1B002CC607C5****"
// Last-Modified: Fri, 24 Feb 2012 06:07:48 GMT
// Content-Length: 344606
// Content-Type: image/jpeg
// Connection: keep-alive
// Server: AliyunOSS
// x-oss-transition-time: Tue, 23 Apr 2024 07:21:42 GMT
// x-oss-last-access-time: Thu, 14 Oct 2021 11:49:05 GMT
// x-oss-storage-class: Standard
// x-oss-server-side-encryption: AES256
//
// === SDK 使用示例 ===
// ```dart
// final ObjectMeta meta = await client.getObjectMeta('oss.jpg');
// print(meta.eTag);           // '"5B3C1A2E053D763E1B002CC607C5****"'
// print(meta.contentLength);  // 344606
// print(meta.contentType);    // 'image/jpeg'
// print(meta.lastModified);   // DateTime(2012, 2, 24, 6, 7, 48)
// print(meta.storageClass);   // 'Standard'
// ```

import '../../util/oss_response.dart';

/// Metadata about an OSS object (returned by HeadObject or GetObjectMeta).
class ObjectMeta {
  const ObjectMeta({
    required this.lastModified,
    required this.eTag,
    required this.contentType,
    required this.contentLength,
    this.contentEncoding,
    this.contentDisposition,
    this.contentMd5,
    this.cacheControl,
    this.expiration,
    this.versionId,
    this.storageClass,
    this.serverSideEncryption,
    this.objectType,
    this.restore,
    this.lastAccessTime,
  });

  /// The last modified time.
  /// HTTP Header: Last-Modified
  final DateTime lastModified;

  /// The ETag of the object.
  /// HTTP Header: ETag
  final String eTag;

  /// The content type.
  /// HTTP Header: Content-Type
  final String contentType;

  /// The content length in bytes.
  /// HTTP Header: Content-Length
  final int contentLength;

  /// The content encoding.
  /// HTTP Header: Content-Encoding
  final String? contentEncoding;

  /// The content disposition.
  /// HTTP Header: Content-Disposition
  final String? contentDisposition;

  /// The content MD5.
  /// HTTP Header: Content-MD5
  final String? contentMd5;

  /// The cache control header.
  /// HTTP Header: Cache-Control
  final String? cacheControl;

  /// The expiration time.
  /// HTTP Header: Expiration
  final DateTime? expiration;

  /// The version ID.
  /// HTTP Header: x-oss-version-id
  final String? versionId;

  /// The storage class.
  /// HTTP Header: x-oss-storage-class
  final String? storageClass;

  /// The server-side encryption algorithm.
  /// HTTP Header: x-oss-server-side-encryption
  final String? serverSideEncryption;

  /// The object type (Normal, Multipart, Appendable).
  /// HTTP Header: x-oss-object-type
  final String? objectType;

  /// The restore status (for archive objects).
  /// HTTP Header: x-oss-restore
  final String? restore;

  /// The last access time (when access tracking is enabled).
  /// HTTP Header: x-oss-last-access-time
  final DateTime? lastAccessTime;

  factory ObjectMeta.fromOssResponse(OssResponse<void> response) {
    final h = response.headers;
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return ObjectMeta(
      lastModified: parseDate(h['last-modified']) ?? DateTime.now(),
      eTag: h['etag'] ?? '',
      contentType: h['content-type'] ?? 'application/octet-stream',
      contentLength: int.tryParse(h['content-length'] ?? '0') ?? 0,
      contentEncoding: h['content-encoding'],
      contentDisposition: h['content-disposition'],
      contentMd5: h['content-md5'],
      cacheControl: h['cache-control'],
      expiration: parseDate(h['expiration']),
      versionId: h['x-oss-version-id'],
      storageClass: h['x-oss-storage-class'],
      serverSideEncryption: h['x-oss-server-side-encryption'],
      objectType: h['x-oss-object-type'],
      restore: h['x-oss-restore'],
      lastAccessTime: parseDate(h['x-oss-last-access-time']),
    );
  }
}
