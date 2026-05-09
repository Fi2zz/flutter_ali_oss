// 阿里云 OSS GetBucketAcl API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/getbucketacl
//
// === 阿里云官方请求示例 ===
// GET /?acl HTTP/1.1
// Host: bucket.oss-cn-zhangjiakou.aliyuncs.com
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例（XML）===
// HTTP/1.1 200 OK
// Content-Type: application/xml
// x-oss-request-id: 5CAC0A3DB7AEADE01700****
//
// <AccessControlPolicy>
//   <Owner>
//     <ID>0022012****</ID>
//     <DisplayName>user_example</DisplayName>
//   </Owner>
//   <AccessControlList>
//     <Grant>private</Grant>
//   </AccessControlList>
// </AccessControlPolicy>
//
// === SDK 使用示例 ===
// ```dart
// final BucketAcl acl = await client.getBucketAcl();
// print(acl.grant); // 'private' (也可以是 'public-read' 或 'public-read-write')
// print(acl.owner?.id);          // '0022012****'
// print(acl.owner?.displayName); // 'user_example'
// ```

import 'package:xml/xml.dart';

/// Access control list of a bucket.
class BucketAcl {
  const BucketAcl({
    required this.grant,
    this.owner,
  });

  /// The ACL grant (e.g., "private", "public-read", "public-read-write").
  /// XML path: AccessControlPolicy/AccessControlList/Grant
  final String grant;

  /// The owner of the bucket.
  /// XML path: AccessControlPolicy/Owner
  final BucketOwner? owner;

  factory BucketAcl.fromXml(XmlDocument xml) {
    final root = xml.rootElement;
    return BucketAcl(
      grant: root.getElement('AccessControlList')?.getElement('Grant')?.innerText ?? 'private',
      owner: root.getElement('Owner') != null
          ? BucketOwner.fromXml(root.getElement('Owner')!)
          : null,
    );
  }
}

/// Owner information in ACL response.
class BucketOwner {
  const BucketOwner({
    required this.id,
    required this.displayName,
  });

  /// XML path: Owner/ID
  final String id;

  /// XML path: Owner/DisplayName
  final String displayName;

  factory BucketOwner.fromXml(XmlElement xml) {
    return BucketOwner(
      id: xml.getElement('ID')?.innerText ?? '',
      displayName: xml.getElement('DisplayName')?.innerText ?? '',
    );
  }
}
