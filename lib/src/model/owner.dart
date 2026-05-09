// 阿里云 OSS Owner 数据模型
// 对应 ListBuckets / ListObjectsV2 响应中的 Owner 元素
// ListBuckets 文档: https://help.aliyun.com/zh/oss/developer-reference/listbuckets
// ListObjectsV2 文档: https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2
//
// === 阿里云官方 XML 格式 ===
// <Owner>
//   <ID>0022012****</ID>
//   <DisplayName>user_example</DisplayName>
// </Owner>

import 'package:xml/xml.dart';

/// Represents the owner of a bucket or object in OSS.
class Owner {
  const Owner({
    required this.id,
    required this.displayName,
  });

  /// The user ID of the owner.
  /// XML path: Owner/ID
  final String id;

  /// The display name of the owner.
  /// XML path: Owner/DisplayName
  final String displayName;

  factory Owner.fromXml(XmlElement xml) {
    return Owner(
      id: xml.getElement('ID')?.innerText ?? '',
      displayName: xml.getElement('DisplayName')?.innerText ?? '',
    );
  }
}
