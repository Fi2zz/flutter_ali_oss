// 阿里云 OSS Region 数据模型
// 对应 GetRegion 响应中的 RegionItem 元素
// 文档: https://help.aliyun.com/zh/oss/developer-reference/regions-endpoints
//
// === 阿里云官方响应中的 RegionItem 元素（XML）===
// <RegionItem>
//   <Region>oss-cn-hangzhou</Region>
//   <InternetEndpoint>oss-cn-hangzhou.aliyuncs.com</InternetEndpoint>
//   <InternalEndpoint>oss-cn-hangzhou-internal.aliyuncs.com</InternalEndpoint>
//   <AccelerateEndpoint>oss-accelerate.aliyuncs.com</AccelerateEndpoint>
//   <VpcInternetEndpoint>vpc100-oss-cn-hangzhou.aliyuncs.com</VpcInternetEndpoint>
//   <VpcInternalEndpoint>vpc100-oss-cn-hangzhou-internal.aliyuncs.com</VpcInternalEndpoint>
// </RegionItem>

import 'package:xml/xml.dart';

/// Represents an OSS region.
class Region {
  const Region({
    required this.region,
    required this.internetEndpoint,
    required this.internalEndpoint,
    required this.accelerateEndpoint,
    this.vpcInternetEndpoint,
    this.vpcInternalEndpoint,
  });

  /// The region ID (e.g., "oss-cn-hangzhou").
  /// XML path: RegionItem/Region
  final String region;

  /// The internet endpoint for this region.
  /// XML path: RegionItem/InternetEndpoint
  final String internetEndpoint;

  /// The internal endpoint for this region.
  /// XML path: RegionItem/InternalEndpoint
  final String internalEndpoint;

  /// The transfer acceleration endpoint.
  /// XML path: RegionItem/AccelerateEndpoint
  final String accelerateEndpoint;

  /// The VPC internet endpoint.
  /// XML path: RegionItem/VpcInternetEndpoint
  final String? vpcInternetEndpoint;

  /// The VPC internal endpoint.
  /// XML path: RegionItem/VpcInternalEndpoint
  final String? vpcInternalEndpoint;

  factory Region.fromXml(XmlElement xml) {
    return Region(
      region: xml.getElement('Region')?.innerText ?? '',
      internetEndpoint: xml.getElement('InternetEndpoint')?.innerText ?? '',
      internalEndpoint: xml.getElement('InternalEndpoint')?.innerText ?? '',
      accelerateEndpoint: xml.getElement('AccelerateEndpoint')?.innerText ?? '',
      vpcInternetEndpoint: xml.getElement('VpcInternetEndpoint')?.innerText,
      vpcInternalEndpoint: xml.getElement('VpcInternalEndpoint')?.innerText,
    );
  }
}
