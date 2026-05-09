// 阿里云 OSS GetBucketStat API 响应模型
// 文档: https://help.aliyun.com/zh/oss/developer-reference/getbucketstat
//
// === 阿里云官方请求示例 ===
// GET /?stat HTTP/1.1
// Host: bucket.oss-cn-zhangjiakou.aliyuncs.com
// Authorization: OSS4-HMAC-SHA256 ...
//
// === 阿里云官方响应示例（XML）===
// HTTP/1.1 200 OK
// Content-Type: application/xml
// x-oss-request-id: 5CAC0A3DB7AEADE01700****
//
// <BucketStat>
//   <Storage>1600</Storage>
//   <ObjectCount>230</ObjectCount>
//   <MultipartUploadCount>40</MultipartUploadCount>
//   <LiveChannelCount>10</LiveChannelCount>
//   <LastModifiedTime>2021-11-05T10:09:13.000Z</LastModifiedTime>
//   <StandardStorage>1600</StandardStorage>
//   <StandardObjectCount>230</StandardObjectCount>
//   <InfrequentAccessStorage>0</InfrequentAccessStorage>
//   <InfrequentAccessObjectCount>0</InfrequentAccessObjectCount>
//   <ArchiveStorage>0</ArchiveStorage>
//   <ArchiveObjectCount>0</ArchiveObjectCount>
//   <ColdArchiveStorage>0</ColdArchiveStorage>
//   <ColdArchiveObjectCount>0</ColdArchiveObjectCount>
//   <DeepColdArchiveStorage>0</DeepColdArchiveStorage>
//   <DeepColdArchiveObjectCount>0</DeepColdArchiveObjectCount>
//   <DeleteMarkerCount>0</DeleteMarkerCount>
// </BucketStat>
//
// === SDK 使用示例 ===
// ```dart
// final BucketStat stat = await client.getBucketStat();
// print(stat.storage);                // 1600 (总存储量 bytes)
// print(stat.objectCount);            // 230
// print(stat.multipartUploadCount);   // 40
// print(stat.liveChannelCount);       // 10
// print(stat.standardStorage);        // 1600
// print(stat.archiveStorage);         // 0
// print(stat.deleteMarkerCount);      // 0
// ```

import 'package:xml/xml.dart';

/// Statistics about a bucket.
class BucketStat {
  const BucketStat({
    required this.storage,
    required this.objectCount,
    required this.multipartUploadCount,
    required this.liveChannelCount,
    required this.lastModifiedTime,
    required this.standardStorage,
    required this.standardObjectCount,
    required this.infrequentAccessStorage,
    required this.infrequentAccessObjectCount,
    required this.archiveStorage,
    required this.archiveObjectCount,
    required this.coldArchiveStorage,
    required this.coldArchiveObjectCount,
    required this.deepColdArchiveStorage,
    required this.deepColdArchiveObjectCount,
    required this.deleteMarkerCount,
  });

  /// The total storage size in bytes.
  /// XML path: BucketStat/Storage
  final int storage;

  /// The total number of objects.
  /// XML path: BucketStat/ObjectCount
  final int objectCount;

  /// The number of multipart uploads in progress.
  /// XML path: BucketStat/MultipartUploadCount
  final int multipartUploadCount;

  /// The number of live channels.
  /// XML path: BucketStat/LiveChannelCount
  final int liveChannelCount;

  /// The last modified time.
  /// XML path: BucketStat/LastModifiedTime
  final DateTime lastModifiedTime;

  /// Standard storage size in bytes.
  /// XML path: BucketStat/StandardStorage
  final int standardStorage;

  /// Standard object count.
  /// XML path: BucketStat/StandardObjectCount
  final int standardObjectCount;

  /// Infrequent access storage size in bytes.
  /// XML path: BucketStat/InfrequentAccessStorage
  final int infrequentAccessStorage;

  /// Infrequent access object count.
  /// XML path: BucketStat/InfrequentAccessObjectCount
  final int infrequentAccessObjectCount;

  /// Archive storage size in bytes.
  /// XML path: BucketStat/ArchiveStorage
  final int archiveStorage;

  /// Archive object count.
  /// XML path: BucketStat/ArchiveObjectCount
  final int archiveObjectCount;

  /// Cold archive storage size in bytes.
  /// XML path: BucketStat/ColdArchiveStorage
  final int coldArchiveStorage;

  /// Cold archive object count.
  /// XML path: BucketStat/ColdArchiveObjectCount
  final int coldArchiveObjectCount;

  /// Deep cold archive storage size in bytes.
  /// XML path: BucketStat/DeepColdArchiveStorage
  final int deepColdArchiveStorage;

  /// Deep cold archive object count.
  /// XML path: BucketStat/DeepColdArchiveObjectCount
  final int deepColdArchiveObjectCount;

  /// Delete marker count.
  /// XML path: BucketStat/DeleteMarkerCount
  final int deleteMarkerCount;

  factory BucketStat.fromXml(XmlDocument xml) {
    final root = xml.rootElement.getElement('BucketStat');
    if (root == null) {
      throw const FormatException('Invalid BucketStat XML: missing BucketStat element');
    }
    int getInt(String tag) => int.tryParse(root.getElement(tag)?.innerText ?? '0') ?? 0;
    return BucketStat(
      storage: getInt('Storage'),
      objectCount: getInt('ObjectCount'),
      multipartUploadCount: getInt('MultipartUploadCount'),
      liveChannelCount: getInt('LiveChannelCount'),
      lastModifiedTime: DateTime.tryParse(root.getElement('LastModifiedTime')?.innerText ?? '') ?? DateTime.now(),
      standardStorage: getInt('StandardStorage'),
      standardObjectCount: getInt('StandardObjectCount'),
      infrequentAccessStorage: getInt('InfrequentAccessStorage'),
      infrequentAccessObjectCount: getInt('InfrequentAccessObjectCount'),
      archiveStorage: getInt('ArchiveStorage'),
      archiveObjectCount: getInt('ArchiveObjectCount'),
      coldArchiveStorage: getInt('ColdArchiveStorage'),
      coldArchiveObjectCount: getInt('ColdArchiveObjectCount'),
      deepColdArchiveStorage: getInt('DeepColdArchiveStorage'),
      deepColdArchiveObjectCount: getInt('DeepColdArchiveObjectCount'),
      deleteMarkerCount: getInt('DeleteMarkerCount'),
    );
  }
}
