import 'dart:io';

import 'package:flutter_alioss/src/model/request/multipart_upload_request.dart';
import 'package:flutter_alioss/src/model/result/multipart_upload_result.dart';
import 'package:flutter_alioss/src/model/result/put_object_result.dart';
import 'package:flutter_alioss/src/util/multipart_upload_checkpoint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UploadFileRequest selects upload mode by threshold', () {
    const request = UploadFileRequest(
      filepath: '/tmp/demo.bin',
      multipartThreshold: 1024,
    );

    expect(request.modeFor(128), UploadMode.simple);
    expect(request.modeFor(2048), UploadMode.multipart);
  });

  test('UploadFileResult builds from simple and multipart results', () {
    const put = PutObjectResult(eTag: '"etag-1"', statusCode: 200);
    const multipart = CompleteMultipartUploadResult(
      location: 'https://bucket.endpoint/demo.bin',
      bucket: 'bucket',
      key: 'demo.bin',
      eTag: '"etag-2"',
    );
    final simpleResult = UploadFileResult.fromPutObject(
      'bucket',
      'demo.bin',
      'https://bucket.endpoint/demo.bin',
      put,
    );
    final multipartResult = UploadFileResult.fromMultipart(multipart);

    expect(simpleResult.mode, UploadMode.simple);
    expect(simpleResult.statusCode, 200);
    expect(multipartResult.mode, UploadMode.multipart);
    expect(multipartResult.location, 'https://bucket.endpoint/demo.bin');
  });

  test('MultipartUploadCheckpointStore saves and loads checkpoint', () async {
    final tempDir = await Directory.systemTemp.createTemp('oss-checkpoint');
    final file = await File('${tempDir.path}/demo.bin').writeAsBytes([1, 2, 3]);
    const store = MultipartUploadCheckpointStore();
    final request = MultipartUploadFileRequest(
      filepath: file.path,
      key: 'demo.bin',
      resumable: true,
      checkpointDir: tempDir.path,
    );

    final created = await store.create(
      request,
      'bucket',
      'demo.bin',
      file,
      'upload-1',
      1024,
    );
    final saved = await store.savePart(
      created!,
      const UploadedPart(partNumber: 1, eTag: '"etag"', size: 3),
    );
    final loaded = await store.load(request, 'bucket', 'demo.bin', file);

    expect(loaded?.uploadId, 'upload-1');
    expect(loaded?.parts.single.partNumber, 1);
    expect(saved.parts.single.size, 3);

    await store.delete(loaded);
    expect(File(created.path).existsSync(), false);
    await tempDir.delete(recursive: true);
  });

  test('MultipartUploadCheckpointStore drops stale checkpoint', () async {
    final tempDir = await Directory.systemTemp.createTemp('oss-checkpoint');
    final file = await File('${tempDir.path}/demo.bin').writeAsBytes([1, 2, 3]);
    const store = MultipartUploadCheckpointStore();
    final request = MultipartUploadFileRequest(
      filepath: file.path,
      key: 'demo.bin',
      resumable: true,
      checkpointDir: tempDir.path,
    );

    final checkpoint = await store.create(
      request,
      'bucket',
      'demo.bin',
      file,
      'upload-2',
      1024,
    );
    await file.writeAsBytes([1, 2, 3, 4]);
    final loaded = await store.load(request, 'bucket', 'demo.bin', file);

    expect(loaded, isNull);
    expect(File(checkpoint!.path).existsSync(), false);
    await tempDir.delete(recursive: true);
  });
}
