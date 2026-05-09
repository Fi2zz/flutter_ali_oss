// 阿里云 OSS Object 数据模型
// 对应 ListObjectsV2 / GetObjectMeta 响应中的 Contents 元素
// 阿里云文档: https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2
//
// === 阿里云官方 ListObjectsV2 响应示例（XML）===
// <Contents>
//   <Key>example/object.txt</Key>
//   <LastModified>2025-05-07T10:00:00.000Z</LastModified>
//   <ETag>"D41D8CD98F00B204E9800998ECF8****"</ETag>
//   <Size>344606</Size>
//   <StorageClass>Standard</StorageClass>
//   <Type>Normal</Type>
//   <Owner>
//     <ID>0022012****</ID>
//     <DisplayName>user_example</DisplayName>
//   </Owner>
// </Contents>
//
// === SDK 使用示例 ===
// ```dart
// final ListObjectsResult result = await client.listObjects(
//   const ListObjectsRequest(maxKeys: 10),
// );
// for (final object in result.objects) {
//   print(object.key);           // "example/object.txt"
//   print(object.size);          // 344606
//   print(object.lastModified);  // DateTime(2025, 5, 7, 10, 0)
//   print(object.eTag);          // '"D41D8CD98F00B204E9800998ECF8****"'
//   print(object.storageClass);  // "Standard"
//   print(object.type);          // "Normal"
// }
// ```

import 'package:xml/xml.dart';

import 'owner.dart';

/// Represents an object stored in OSS.
class OSSObject {
  const OSSObject({
    required this.key,
    required this.lastModified,
    required this.eTag,
    required this.size,
    required this.storageClass,
    this.type,
    this.owner,
    this.restoreInfo,
    this.sealedTime,
  });

  /// The key (name) of the object.
  /// XML path: Contents/Key
  final String key;

  /// The last modified time of the object.
  /// XML path: Contents/LastModified
  final DateTime lastModified;

  /// The ETag of the object.
  /// XML path: Contents/ETag
  final String eTag;

  /// The size of the object in bytes.
  /// XML path: Contents/Size
  final int size;

  /// The storage class of the object.
  /// XML path: Contents/StorageClass
  /// Possible values: "Standard", "IA", "Archive", "ColdArchive", "DeepColdArchive"
  /// 阿里云文档: https://help.aliyun.com/zh/oss/user-guide/overview-of-storage-classes
  final String storageClass;

  /// The type of the object.
  /// XML path: Contents/Type
  /// Possible values: "Normal", "Multipart", "Appendable", "Symlink"
  final String? type;

  /// The owner of the object (only present when fetchOwner is true).
  /// XML path: Contents/Owner
  final Owner? owner;

  /// The restore status of the object (for archive objects).
  /// XML path: Contents/RestoreInfo
  final String? restoreInfo;

  /// The sealed time for appendable objects.
  /// XML path: Contents/SealedTime
  final DateTime? sealedTime;

  factory OSSObject.fromXml(XmlElement xml) {
    DateTime? parseDateTime(String? text) {
      if (text == null || text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return OSSObject(
      key: xml.getElement('Key')?.innerText ?? '',
      lastModified: parseDateTime(xml.getElement('LastModified')?.innerText) ?? DateTime.now(),
      eTag: xml.getElement('ETag')?.innerText ?? '',
      size: int.tryParse(xml.getElement('Size')?.innerText ?? '0') ?? 0,
      storageClass: xml.getElement('StorageClass')?.innerText ?? 'STANDARD',
      type: xml.getElement('Type')?.innerText,
      owner: xml.getElement('Owner') != null
          ? Owner.fromXml(xml.getElement('Owner')!)
          : null,
      restoreInfo: xml.getElement('RestoreInfo')?.innerText,
      sealedTime: parseDateTime(xml.getElement('SealedTime')?.innerText),
    );
  }
}
