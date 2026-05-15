import 'package:flutter_alioss/src/model/request.dart';
import 'package:flutter_alioss/src/model/result/multipart_upload_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  test('HttpRequest keeps valueless uploads query', () {
    final req = HttpRequest.get(
      'https://examplebucket.oss-cn-hangzhou.aliyuncs.com',
      parameters: {'uploads': ''},
    );

    expect(
        req.url, 'https://examplebucket.oss-cn-hangzhou.aliyuncs.com?uploads');
  });

  test('ListMultipartUploadsResult parses uploads and markers', () {
    final xml = XmlDocument.parse('''
      <ListMultipartUploadsResult>
        <Bucket>examplebucket</Bucket>
        <NextKeyMarker>demo.txt</NextKeyMarker>
        <NextUploadIdMarker>upload-next</NextUploadIdMarker>
        <MaxUploads>1000</MaxUploads>
        <IsTruncated>false</IsTruncated>
        <Upload>
          <Key>demo.txt</Key>
          <UploadId>upload-1</UploadId>
          <Initiated>2025-01-01T00:00:00.000Z</Initiated>
        </Upload>
      </ListMultipartUploadsResult>
    ''');
    final result = ListMultipartUploadsResult.fromXml(xml);

    expect(result.bucket, 'examplebucket');
    expect(result.nextKeyMarker, 'demo.txt');
    expect(result.nextUploadIdMarker, 'upload-next');
    expect(result.uploads.single.uploadId, 'upload-1');
  });

  test('ListPartsResult parses part list', () {
    final xml = XmlDocument.parse('''
      <ListPartsResult>
        <Bucket>examplebucket</Bucket>
        <Key>demo.txt</Key>
        <UploadId>upload-1</UploadId>
        <PartNumberMarker>0</PartNumberMarker>
        <NextPartNumberMarker>2</NextPartNumberMarker>
        <MaxParts>1000</MaxParts>
        <IsTruncated>false</IsTruncated>
        <Part>
          <PartNumber>1</PartNumber>
          <LastModified>2025-01-01T00:00:00.000Z</LastModified>
          <ETag>"etag-1"</ETag>
          <Size>5242880</Size>
        </Part>
      </ListPartsResult>
    ''');
    final result = ListPartsResult.fromXml(xml);

    expect(result.key, 'demo.txt');
    expect(result.uploadId, 'upload-1');
    expect(result.parts.single.partNumber, 1);
    expect(result.parts.single.size, 5242880);
  });
}
