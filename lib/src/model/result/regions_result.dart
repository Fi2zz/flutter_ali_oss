// 阿里云 OSS GetRegion API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/regions-endpoints
//
// === 阿里云官方请求示例 ===
// GET /?regions HTTP/1.1
// Host: oss.aliyuncs.com
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例（XML）===
// HTTP/1.1 200 OK
// Content-Type: application/xml
// x-oss-request-id: 5CAC0A3DB7AEADE01700****
//
// <RegionInfo>
//   <RegionItem>
//     <Region>oss-cn-hangzhou</Region>
//     <InternetEndpoint>oss-cn-hangzhou.aliyuncs.com</InternetEndpoint>
//     <InternalEndpoint>oss-cn-hangzhou-internal.aliyuncs.com</InternalEndpoint>
//     <AccelerateEndpoint>oss-accelerate.aliyuncs.com</AccelerateEndpoint>
//     <VpcInternetEndpoint>vpc100-oss-cn-hangzhou.aliyuncs.com</VpcInternetEndpoint>
//     <VpcInternalEndpoint>vpc100-oss-cn-hangzhou-internal.aliyuncs.com</VpcInternalEndpoint>
//   </RegionItem>
// </RegionInfo>
//
// === SDK 使用示例 ===
// ```dart
// final RegionsResult result = await client.getAllRegions();
// for (final region in result.regions) {
//   print(region.region);               // 'oss-cn-hangzhou'
//   print(region.internetEndpoint);     // 'oss-cn-hangzhou.aliyuncs.com'
//   print(region.internalEndpoint);     // 'oss-cn-hangzhou-internal.aliyuncs.com'
//   print(region.accelerateEndpoint);   // 'oss-accelerate.aliyuncs.com'
// }
// ```

import 'package:xml/xml.dart';

import '../region.dart';

/// Result of listing all supported regions.
class RegionsResult {
  const RegionsResult({
    required this.regions,
  });

  /// The list of regions.
  /// XML path: RegionInfo/RegionItem[]
  final List<Region> regions;

  factory RegionsResult.fromXml(XmlDocument xml) {
    final root = xml.rootElement;
    return RegionsResult(
      regions: root.findAllElements('RegionItem').map((e) => Region.fromXml(e)).toList(),
    );
  }
}
