// 阿里云 OSS CommonPrefix 数据模型
// 对应 ListObjectsV2 响应中的 CommonPrefixes 元素
// 文档: https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2
//
// === 阿里云官方 XML 格式 ===
// <CommonPrefixes>
//   <Prefix>example/a</Prefix>
// </CommonPrefixes>

import 'package:xml/xml.dart';

/// Represents a common prefix returned when using delimiter in list operations.
class CommonPrefix {
  const CommonPrefix({
    required this.prefix,
  });

  /// The common prefix string.
  /// XML path: CommonPrefixes/Prefix
  final String prefix;

  factory CommonPrefix.fromXml(XmlElement xml) {
    return CommonPrefix(
      prefix: xml.getElement('Prefix')?.innerText ?? '',
    );
  }
}
