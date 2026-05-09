// 阿里云 OSS GetBucketInfo API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/getbucketinfo
//
// === 阿里云官方请求示例 ===
// GET /?bucketInfo HTTP/1.1
// Host: bucket.oss-cn-zhangjiakou.aliyuncs.com
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例（XML）===
// HTTP/1.1 200 OK
// Content-Type: application/xml
// x-oss-request-id: 5CAC0A3DB7AEADE01700****
//
// <BucketInfo>
//   <Bucket>
//     <CreationDate>2015-07-24T11:49:13.000Z</CreationDate>
//     <ExtranetEndpoint>oss-cn-zhangjiakou.aliyuncs.com</ExtranetEndpoint>
//     <IntranetEndpoint>oss-cn-zhangjiakou-internal.aliyuncs.com</IntranetEndpoint>
//     <Location>oss-cn-zhangjiakou</Location>
//     <Name>bucket</Name>
//     <AccessControlList>
//       <Grant>private</Grant>
//     </AccessControlList>
//     <StorageClass>Standard</StorageClass>
//     <Versioning>Enabled</Versioning>
//     <TransferAcceleration>Disabled</TransferAcceleration>
//     <Region>cn-zhangjiakou</Region>
//   </Bucket>
// </BucketInfo>
//
// === SDK 使用示例 ===
// ```dart
// final BucketInfo info = await client.getBucketInfo();
// print(info.name);                   // 'bucket'
// print(info.location);               // 'oss-cn-zhangjiakou'
// print(info.region);                 // 'cn-zhangjiakou'
// print(info.creationDate);           // DateTime(2015, 7, 24, 11, 49, 13)
// print(info.extranetEndpoint);       // 'oss-cn-zhangjiakou.aliyuncs.com'
// print(info.intranetEndpoint);       // 'oss-cn-zhangjiakou-internal.aliyuncs.com'
// print(info.acl);                    // 'private'
// print(info.storageClass);           // 'Standard'
// print(info.versioning);             // 'Enabled'
// print(info.transferAcceleration);   // 'Disabled'
// ```

import 'package:xml/xml.dart';

import '../owner.dart';

/// Detailed information about a bucket.
class BucketInfo {
  const BucketInfo({
    required this.name,
    required this.location,
    required this.creationDate,
    required this.extranetEndpoint,
    required this.intranetEndpoint,
    required this.acl,
    required this.storageClass,
    this.region,
    this.sseRule,
    this.versioning,
    this.transferAcceleration,
    this.crossRegionReplication,
    this.resourceGroupId,
    this.blockPublicAccess,
    this.owner,
    this.comment,
    this.accessMonitor,
  });

  /// The name of the bucket.
  /// XML path: BucketInfo/Bucket/Name
  final String name;

  /// The location of the bucket.
  /// XML path: BucketInfo/Bucket/Location
  final String location;

  /// The creation date of the bucket.
  /// XML path: BucketInfo/Bucket/CreationDate
  final DateTime creationDate;

  /// The extranet endpoint.
  /// XML path: BucketInfo/Bucket/ExtranetEndpoint
  final String extranetEndpoint;

  /// The intranet endpoint.
  /// XML path: BucketInfo/Bucket/IntranetEndpoint
  final String intranetEndpoint;

  /// The access control list.
  /// XML path: BucketInfo/Bucket/AccessControlList/Grant
  final String acl;

  /// The storage class.
  /// XML path: BucketInfo/Bucket/StorageClass
  final String storageClass;

  /// The region.
  /// XML path: BucketInfo/Bucket/Region
  final String? region;

  /// The server-side encryption rule.
  /// XML path: BucketInfo/Bucket/ServerSideEncryptionRule
  final String? sseRule;

  /// The versioning status.
  /// XML path: BucketInfo/Bucket/Versioning
  final String? versioning;

  /// The transfer acceleration status.
  /// XML path: BucketInfo/Bucket/TransferAcceleration
  final String? transferAcceleration;

  /// The cross-region replication status.
  /// XML path: BucketInfo/Bucket/CrossRegionReplication
  final String? crossRegionReplication;

  /// The resource group ID.
  /// XML path: BucketInfo/Bucket/ResourceGroupId
  final String? resourceGroupId;

  /// The block public access status.
  /// XML path: BucketInfo/Bucket/BlockPublicAccess
  final String? blockPublicAccess;

  /// The owner of the bucket.
  final Owner? owner;

  /// The comment of the bucket.
  /// XML path: BucketInfo/Bucket/Comment
  final String? comment;

  /// The access monitor status.
  /// XML path: BucketInfo/Bucket/AccessMonitor
  final String? accessMonitor;

  factory BucketInfo.fromXml(XmlDocument xml) {
    final root = xml.rootElement.getElement('Bucket');
    if (root == null) {
      throw const FormatException('Invalid BucketInfo XML: missing Bucket element');
    }
    return BucketInfo(
      name: root.getElement('Name')?.innerText ?? '',
      location: root.getElement('Location')?.innerText ?? '',
      creationDate: DateTime.tryParse(root.getElement('CreationDate')?.innerText ?? '') ?? DateTime.now(),
      extranetEndpoint: root.getElement('ExtranetEndpoint')?.innerText ?? '',
      intranetEndpoint: root.getElement('IntranetEndpoint')?.innerText ?? '',
      acl: root.getElement('AccessControlList')?.getElement('Grant')?.innerText ?? 'private',
      storageClass: root.getElement('StorageClass')?.innerText ?? 'Standard',
      region: root.getElement('Region')?.innerText,
      sseRule: root.getElement('ServerSideEncryptionRule')?.innerText.trim(),
      versioning: root.getElement('Versioning')?.innerText,
      transferAcceleration: root.getElement('TransferAcceleration')?.innerText,
      crossRegionReplication: root.getElement('CrossRegionReplication')?.innerText,
      resourceGroupId: root.getElement('ResourceGroupId')?.innerText,
      blockPublicAccess: root.getElement('BlockPublicAccess')?.innerText,
      owner: root.getElement('Owner') != null
          ? Owner.fromXml(root.getElement('Owner')!)
          : null,
      comment: root.getElement('Comment')?.innerText,
      accessMonitor: root.getElement('AccessMonitor')?.innerText,
    );
  }
}
