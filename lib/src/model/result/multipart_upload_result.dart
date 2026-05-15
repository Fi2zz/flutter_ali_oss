import 'package:xml/xml.dart';

import '../request/multipart_upload_request.dart';
import '../common_prefix.dart';
import '../../util/oss_response.dart';
import 'put_object_result.dart';

class InitiateMultipartUploadResult {
  const InitiateMultipartUploadResult({
    required this.bucket,
    required this.key,
    required this.uploadId,
    this.encodingType,
  });

  final String bucket;
  final String key;
  final String uploadId;
  final String? encodingType;

  factory InitiateMultipartUploadResult.fromXml(XmlDocument xml) {
    final root = xml.rootElement;
    return InitiateMultipartUploadResult(
      bucket: root.getElement('Bucket')?.innerText ?? '',
      key: root.getElement('Key')?.innerText ?? '',
      uploadId: root.getElement('UploadId')?.innerText ?? '',
      encodingType: root.getElement('EncodingType')?.innerText,
    );
  }
}

class UploadPartResult {
  const UploadPartResult({
    required this.partNumber,
    required this.statusCode,
    required this.eTag,
    this.contentMd5,
    this.hashCrc64,
  });

  final int partNumber;
  final int statusCode;
  final String eTag;
  final String? contentMd5;
  final String? hashCrc64;

  factory UploadPartResult.fromOssResponse(
    int partNumber,
    StringResponse response,
  ) {
    final headers = response.headers;
    return UploadPartResult(
      partNumber: partNumber,
      statusCode: response.statusCode,
      eTag: headers['etag'] ?? '',
      contentMd5: headers['content-md5'],
      hashCrc64: headers['x-oss-hash-crc64ecma'],
    );
  }
}

class CompleteMultipartUploadResult {
  const CompleteMultipartUploadResult({
    required this.location,
    required this.bucket,
    required this.key,
    required this.eTag,
    this.versionId,
    this.encodingType,
  });

  final String location;
  final String bucket;
  final String key;
  final String eTag;
  final String? versionId;
  final String? encodingType;

  factory CompleteMultipartUploadResult.fromXml(
    XmlDocument xml,
    Map<String, String> headers,
  ) {
    final root = xml.rootElement;
    return CompleteMultipartUploadResult(
      location: root.getElement('Location')?.innerText ?? '',
      bucket: root.getElement('Bucket')?.innerText ?? '',
      key: root.getElement('Key')?.innerText ?? '',
      eTag: root.getElement('ETag')?.innerText ?? '',
      versionId: headers['x-oss-version-id'],
      encodingType: root.getElement('EncodingType')?.innerText,
    );
  }
}

class MultipartUploadSummary {
  const MultipartUploadSummary({
    required this.key,
    required this.uploadId,
    required this.initiated,
  });

  final String key;
  final String uploadId;
  final DateTime initiated;

  factory MultipartUploadSummary.fromXml(XmlElement xml) {
    return MultipartUploadSummary(
      key: xml.getElement('Key')?.innerText ?? '',
      uploadId: xml.getElement('UploadId')?.innerText ?? '',
      initiated: DateTime.tryParse(
            xml.getElement('Initiated')?.innerText ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

class ListMultipartUploadsResult {
  const ListMultipartUploadsResult({
    required this.bucket,
    required this.maxUploads,
    required this.isTruncated,
    required this.uploads,
    required this.commonPrefixes,
    this.keyMarker,
    this.uploadIdMarker,
    this.nextKeyMarker,
    this.nextUploadIdMarker,
    this.prefix,
    this.delimiter,
    this.encodingType,
  });

  final String bucket;
  final int maxUploads;
  final bool isTruncated;
  final List<MultipartUploadSummary> uploads;
  final List<CommonPrefix> commonPrefixes;
  final String? keyMarker;
  final String? uploadIdMarker;
  final String? nextKeyMarker;
  final String? nextUploadIdMarker;
  final String? prefix;
  final String? delimiter;
  final String? encodingType;

  factory ListMultipartUploadsResult.fromXml(XmlDocument xml) {
    final root = xml.rootElement;
    return ListMultipartUploadsResult(
      bucket: root.getElement('Bucket')?.innerText ?? '',
      maxUploads:
          int.tryParse(root.getElement('MaxUploads')?.innerText ?? '0') ?? 0,
      isTruncated: (root.getElement('IsTruncated')?.innerText ?? 'false')
              .toLowerCase() ==
          'true',
      uploads: root
          .findAllElements('Upload')
          .map(MultipartUploadSummary.fromXml)
          .toList(),
      commonPrefixes: root
          .findAllElements('CommonPrefixes')
          .map(CommonPrefix.fromXml)
          .toList(),
      keyMarker: root.getElement('KeyMarker')?.innerText,
      uploadIdMarker: root.getElement('UploadIdMarker')?.innerText,
      nextKeyMarker: root.getElement('NextKeyMarker')?.innerText,
      nextUploadIdMarker: root.getElement('NextUploadIdMarker')?.innerText ??
          root.getElement('NextUploadMarker')?.innerText,
      prefix: root.getElement('Prefix')?.innerText,
      delimiter: root.getElement('Delimiter')?.innerText,
      encodingType: root.getElement('EncodingType')?.innerText,
    );
  }
}

class PartSummary {
  const PartSummary({
    required this.partNumber,
    required this.lastModified,
    required this.eTag,
    required this.size,
  });

  final int partNumber;
  final DateTime lastModified;
  final String eTag;
  final int size;

  factory PartSummary.fromXml(XmlElement xml) {
    return PartSummary(
      partNumber:
          int.tryParse(xml.getElement('PartNumber')?.innerText ?? '0') ?? 0,
      lastModified: DateTime.tryParse(
            xml.getElement('LastModified')?.innerText ?? '',
          ) ??
          DateTime.now(),
      eTag: xml.getElement('ETag')?.innerText ?? '',
      size: int.tryParse(xml.getElement('Size')?.innerText ?? '0') ?? 0,
    );
  }
}

class ListPartsResult {
  const ListPartsResult({
    required this.bucket,
    required this.key,
    required this.uploadId,
    required this.partNumberMarker,
    required this.nextPartNumberMarker,
    required this.maxParts,
    required this.isTruncated,
    required this.parts,
    this.encodingType,
  });

  final String bucket;
  final String key;
  final String uploadId;
  final int partNumberMarker;
  final int nextPartNumberMarker;
  final int maxParts;
  final bool isTruncated;
  final List<PartSummary> parts;
  final String? encodingType;

  factory ListPartsResult.fromXml(XmlDocument xml) {
    final root = xml.rootElement;
    return ListPartsResult(
      bucket: root.getElement('Bucket')?.innerText ?? '',
      key: root.getElement('Key')?.innerText ?? '',
      uploadId: root.getElement('UploadId')?.innerText ?? '',
      partNumberMarker:
          int.tryParse(root.getElement('PartNumberMarker')?.innerText ?? '0') ??
              0,
      nextPartNumberMarker: int.tryParse(
            root.getElement('NextPartNumberMarker')?.innerText ?? '0',
          ) ??
          0,
      maxParts:
          int.tryParse(root.getElement('MaxParts')?.innerText ?? '0') ?? 0,
      isTruncated: (root.getElement('IsTruncated')?.innerText ?? 'false')
              .toLowerCase() ==
          'true',
      parts: root.findAllElements('Part').map(PartSummary.fromXml).toList(),
      encodingType: root.getElement('EncodingType')?.innerText,
    );
  }
}

class UploadFileResult {
  const UploadFileResult({
    required this.mode,
    required this.bucket,
    required this.key,
    required this.eTag,
    required this.location,
    required this.statusCode,
    this.versionId,
  });

  final UploadMode mode;
  final String bucket;
  final String key;
  final String eTag;
  final String location;
  final int statusCode;
  final String? versionId;

  factory UploadFileResult.fromPutObject(
    String bucket,
    String key,
    String location,
    PutObjectResult result,
  ) {
    return UploadFileResult(
      mode: UploadMode.simple,
      bucket: bucket,
      key: key,
      eTag: result.eTag,
      location: location,
      statusCode: result.statusCode,
      versionId: result.versionId,
    );
  }

  factory UploadFileResult.fromMultipart(CompleteMultipartUploadResult result) {
    return UploadFileResult(
      mode: UploadMode.multipart,
      bucket: result.bucket,
      key: result.key,
      eTag: result.eTag,
      location: result.location,
      statusCode: 200,
      versionId: result.versionId,
    );
  }
}
