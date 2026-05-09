// 阿里云 OSS ListObjectsV2 API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2
//
// === 阿里云官方请求示例 ===
// GET /?list-type=2 HTTP/1.1
// Host: bucket.oss-cn-zhangjiakou.aliyuncs.com
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例（XML）===
// HTTP/1.1 200 OK
// Content-Type: application/xml
// x-oss-request-id: 5CAC0A3DB7AEADE01700****
//
// <ListBucketResult>
//   <Name>bucket</Name>
//   <Prefix>example</Prefix>
//   <MaxKeys>100</MaxKeys>
//   <Delimiter>/</Delimiter>
//   <IsTruncated>true</IsTruncated>
//   <NextContinuationToken>NextMarker</NextContinuationToken>
//   <ContinuationToken></ContinuationToken>
//   <KeyCount>2</KeyCount>
//   <CommonPrefixes>
//     <Prefix>example/a</Prefix>
//   </CommonPrefixes>
//   <Contents>
//     <Key>example/object.txt</Key>
//     <LastModified>2025-05-07T10:00:00.000Z</LastModified>
//     <ETag>"D41D8CD98F00B204E9800998ECF8****"</ETag>
//     <Size>344606</Size>
//     <StorageClass>Standard</StorageClass>
//     <Type>Normal</Type>
//   </Contents>
// </ListBucketResult>
//
// === SDK 使用示例 ===
// ```dart
// final ListObjectsResult result = await client.listObjects(
//   const ListObjectsRequest(
//     maxKeys: 100,
//     prefix: 'example',
//     delimiter: '/',
//   ),
// );
// print(result.name);                    // "bucket"
// print(result.keyCount);                // 2
// print(result.isTruncated);             // true
// print(result.nextContinuationToken);   // "NextMarker"
// for (final obj in result.objects) {
//   print(obj.key);   // "example/object.txt"
// }
// ```

import 'package:xml/xml.dart';

import '../common_prefix.dart';
import '../oss_object.dart';
import '../owner.dart';

/// Result of listing objects in a bucket (ListObjectsV2).
class ListObjectsResult {
  const ListObjectsResult({
    required this.name,
    required this.prefix,
    required this.maxKeys,
    required this.isTruncated,
    required this.keyCount,
    required this.objects,
    required this.commonPrefixes,
    this.continuationToken,
    this.nextContinuationToken,
    this.startAfter,
    this.delimiter,
    this.encodingType,
    this.owner,
  });

  /// The bucket name.
  /// XML path: ListBucketResult/Name
  final String name;

  /// The prefix used in the request.
  /// XML path: ListBucketResult/Prefix
  final String prefix;

  /// The maximum number of keys returned.
  /// XML path: ListBucketResult/MaxKeys
  final int maxKeys;

  /// Whether the results were truncated.
  /// XML path: ListBucketResult/IsTruncated
  final bool isTruncated;

  /// The number of keys returned.
  /// XML path: ListBucketResult/KeyCount
  final int keyCount;

  /// The list of objects.
  /// XML path: ListBucketResult/Contents[]
  final List<OSSObject> objects;

  /// The list of common prefixes.
  /// XML path: ListBucketResult/CommonPrefixes[]
  final List<CommonPrefix> commonPrefixes;

  /// The continuation token used in the request.
  /// XML path: ListBucketResult/ContinuationToken
  final String? continuationToken;

  /// The next continuation token for pagination.
  /// XML path: ListBucketResult/NextContinuationToken
  final String? nextContinuationToken;

  /// The start-after parameter used in the request.
  /// XML path: ListBucketResult/StartAfter
  final String? startAfter;

  /// The delimiter used in the request.
  /// XML path: ListBucketResult/Delimiter
  final String? delimiter;

  /// The encoding type of the response.
  /// XML path: ListBucketResult/EncodingType
  final String? encodingType;

  /// The owner of the bucket.
  final Owner? owner;

  factory ListObjectsResult.fromXml(XmlDocument xml) {
    final root = xml.rootElement;
    return ListObjectsResult(
      name: root.getElement('Name')?.innerText ?? '',
      prefix: root.getElement('Prefix')?.innerText ?? '',
      maxKeys: int.tryParse(root.getElement('MaxKeys')?.innerText ?? '0') ?? 0,
      isTruncated: (root.getElement('IsTruncated')?.innerText ?? 'false').toLowerCase() == 'true',
      keyCount: int.tryParse(root.getElement('KeyCount')?.innerText ?? '0') ?? 0,
      objects: root.findAllElements('Contents').map((e) => OSSObject.fromXml(e)).toList(),
      commonPrefixes: root.findAllElements('CommonPrefixes').map((e) => CommonPrefix.fromXml(e)).toList(),
      continuationToken: root.getElement('ContinuationToken')?.innerText,
      nextContinuationToken: root.getElement('NextContinuationToken')?.innerText,
      startAfter: root.getElement('StartAfter')?.innerText,
      delimiter: root.getElement('Delimiter')?.innerText,
      encodingType: root.getElement('EncodingType')?.innerText,
      owner: root.getElement('Owner') != null
          ? Owner.fromXml(root.getElement('Owner')!)
          : null,
    );
  }
}
