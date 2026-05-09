// 阿里云 OSS ListBuckets API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/listbuckets
//
// === 阿里云官方请求示例 ===
// GET / HTTP/1.1
// Host: oss-cn-hangzhou.aliyuncs.com
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例（XML）===
// HTTP/1.1 200 OK
// Content-Type: application/xml
// x-oss-request-id: 5CAC0A3DB7AEADE01700****
//
// <ListAllMyBucketsResult>
//   <Owner>
//     <ID>0022012****</ID>
//     <DisplayName>user_example</DisplayName>
//   </Owner>
//   <Buckets>
//     <Bucket>
//       <CreationDate>2015-07-24T11:49:13.000Z</CreationDate>
//       <ExtranetEndpoint>oss-cn-hangzhou.aliyuncs.com</ExtranetEndpoint>
//       <IntranetEndpoint>oss-cn-hangzhou-internal.aliyuncs.com</IntranetEndpoint>
//       <Location>oss-cn-hangzhou</Location>
//       <Name>bucket1</Name>
//       <StorageClass>Standard</StorageClass>
//     </Bucket>
//   </Buckets>
// </ListAllMyBucketsResult>
//
// === SDK 使用示例 ===
// ```dart
// final ListBucketsResult result = await client.listBuckets(
//   const ListBucketsRequest(maxKeys: 100),
// );
// print(result.owner.id);          // '0022012****'
// print(result.owner.displayName); // 'user_example'
// for (final bucket in result.buckets) {
//   print(bucket.name);            // 'bucket1'
//   print(bucket.location);        // 'oss-cn-hangzhou'
//   print(bucket.creationDate);    // DateTime(2015, 7, 24, 11, 49, 13)
//   print(bucket.storageClass);    // 'Standard'
// }
// ```

import 'package:xml/xml.dart';

import '../bucket.dart';
import '../owner.dart';

/// Result of listing all buckets.
class ListBucketsResult {
  const ListBucketsResult({
    required this.buckets,
    required this.owner,
    required this.isTruncated,
    this.prefix,
    this.marker,
    this.maxKeys,
    this.nextMarker,
  });

  /// The list of buckets.
  /// XML path: ListAllMyBucketsResult/Buckets/Bucket[]
  final List<Bucket> buckets;

  /// The owner of the buckets.
  /// XML path: ListAllMyBucketsResult/Owner
  final Owner owner;

  /// Whether the results were truncated.
  /// XML path: ListAllMyBucketsResult/IsTruncated
  final bool isTruncated;

  /// The prefix used in the request.
  /// XML path: ListAllMyBucketsResult/Prefix
  final String? prefix;

  /// The marker used in the request.
  /// XML path: ListAllMyBucketsResult/Marker
  final String? marker;

  /// The maximum number of keys returned.
  /// XML path: ListAllMyBucketsResult/MaxKeys
  final int? maxKeys;

  /// The next marker for pagination.
  /// XML path: ListAllMyBucketsResult/NextMarker
  final String? nextMarker;

  factory ListBucketsResult.fromXml(XmlDocument xml) {
    final root = xml.rootElement;
    return ListBucketsResult(
      buckets: root.findAllElements('Bucket').map((e) => Bucket.fromXml(e)).toList(),
      owner: Owner.fromXml(root.getElement('Owner')!),
      isTruncated: (root.getElement('IsTruncated')?.innerText ?? 'false').toLowerCase() == 'true',
      prefix: root.getElement('Prefix')?.innerText,
      marker: root.getElement('Marker')?.innerText,
      maxKeys: int.tryParse(root.getElement('MaxKeys')?.innerText ?? '0'),
      nextMarker: root.getElement('NextMarker')?.innerText,
    );
  }
}
