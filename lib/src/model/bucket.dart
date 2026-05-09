// 阿里云 OSS Bucket 数据模型
// 对应 ListBuckets / GetBucketInfo 响应中的 Bucket 元素
// ListBuckets 文档: https://help.aliyun.com/zh/oss/developer-reference/listbuckets
// GetBucketInfo 文档: https://help.aliyun.com/zh/oss/developer-reference/getbucketinfo
//
// === 阿里云官方 ListBuckets 响应中的 Bucket 元素（XML）===
// <Bucket>
//   <CreationDate>2015-07-24T11:49:13.000Z</CreationDate>
//   <ExtranetEndpoint>oss-cn-hangzhou.aliyuncs.com</ExtranetEndpoint>
//   <IntranetEndpoint>oss-cn-hangzhou-internal.aliyuncs.com</IntranetEndpoint>
//   <Location>oss-cn-hangzhou</Location>
//   <Name>bucket1</Name>
//   <Region>cn-hangzhou</Region>
//   <StorageClass>Standard</StorageClass>
// </Bucket>

import 'package:xml/xml.dart';

import 'owner.dart';

/// Represents an OSS bucket.
class Bucket {
  const Bucket({
    required this.name,
    required this.creationDate,
    required this.location,
    required this.storageClass,
    this.extranetEndpoint,
    this.intranetEndpoint,
    this.region,
    this.resourceGroupId,
    this.owner,
  });

  /// The name of the bucket.
  /// XML path: Bucket/Name
  final String name;

  /// The creation date of the bucket.
  /// XML path: Bucket/CreationDate
  final DateTime creationDate;

  /// The location of the bucket.
  /// XML path: Bucket/Location
  final String location;

  /// The storage class of the bucket.
  /// XML path: Bucket/StorageClass
  final String storageClass;

  /// The extranet endpoint of the bucket.
  /// XML path: Bucket/ExtranetEndpoint
  final String? extranetEndpoint;

  /// The intranet endpoint of the bucket.
  /// XML path: Bucket/IntranetEndpoint
  final String? intranetEndpoint;

  /// The region of the bucket.
  /// XML path: Bucket/Region
  final String? region;

  /// The resource group ID.
  /// XML path: Bucket/ResourceGroupId
  final String? resourceGroupId;

  /// The owner of the bucket.
  final Owner? owner;

  factory Bucket.fromXml(XmlElement xml) {
    return Bucket(
      name: xml.getElement('Name')?.innerText ?? '',
      creationDate: DateTime.tryParse(xml.getElement('CreationDate')?.innerText ?? '') ?? DateTime.now(),
      location: xml.getElement('Location')?.innerText ?? '',
      storageClass: xml.getElement('StorageClass')?.innerText ?? 'STANDARD',
      extranetEndpoint: xml.getElement('ExtranetEndpoint')?.innerText,
      intranetEndpoint: xml.getElement('IntranetEndpoint')?.innerText,
      region: xml.getElement('Region')?.innerText,
      resourceGroupId: xml.getElement('ResourceGroupId')?.innerText,
      owner: xml.getElement('Owner') != null
          ? Owner.fromXml(xml.getElement('Owner')!)
          : null,
    );
  }
}
