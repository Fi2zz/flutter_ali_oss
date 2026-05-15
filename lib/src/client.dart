// 阿里云对象存储服务（OSS）Flutter SDK
// 基于阿里云 OSS REST API 构建
// 阿里云文档: https://help.aliyun.com/zh/oss/developer-reference/overview

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:xml/xml.dart';

import 'auth_mixin.dart';
import 'client_api.dart';
import 'extension/date_extension.dart';
import 'http_mixin.dart';
import 'model/auth.dart';
import 'model/enums.dart';
import 'model/request.dart';
import 'model/request/append_object_request.dart';
import 'model/request/copy_object_request.dart';
import 'model/request/delete_object_request.dart';
import 'model/request/get_object_request.dart';
import 'model/request/list_buckets_request.dart';
import 'model/request/list_objects_request.dart';
import 'model/request/multipart_upload_request.dart';
import 'model/request/put_object_request.dart';
import 'model/result/append_object_result.dart';
import 'model/result/bucket_acl.dart';
import 'model/result/bucket_info.dart';
import 'model/result/bucket_stat.dart';
import 'model/result/copy_object_result.dart';
import 'model/result/delete_object_result.dart';
import 'model/result/list_buckets_result.dart';
import 'model/result/list_objects_result.dart';
import 'model/result/multipart_upload_result.dart';
import 'model/result/object_meta.dart';
import 'model/result/put_object_result.dart';
import 'model/result/regions_result.dart';
import 'util/cancel_token.dart';
import 'util/multipart_file.dart';
import 'util/multipart_upload_checkpoint.dart';
import 'util/oss_exception.dart';
import 'util/oss_http_client.dart';
import 'util/oss_response.dart';

class Client with AuthMixin, HttpMixin implements ClientApi {
  static Client? _instance;
  factory Client() => _instance!;

  final String endpoint;
  final String bucketName;
  final OssHttpClient _http;
  final MultipartUploadCheckpointStore _checkpoints =
      const MultipartUploadCheckpointStore();

  Client._(
      {required this.endpoint, required this.bucketName, bool logging = false})
      : _http = OssHttpClient(logging: logging);

  static Client init({
    required String ossEndpoint,
    required String bucketName,
    required FutureOr<Auth> Function() authenticator,
    bool logging = false,
  }) {
    _instance = Client._(
        endpoint: ossEndpoint, bucketName: bucketName, logging: logging)
      ..authenticator = authenticator;
    return _instance!;
  }

  // ----- helpers -----

  String _url(String bucket, String path, [Map<String, dynamic>? query]) {
    final sb = StringBuffer('https://$bucket.$endpoint/$path');
    if (query != null && query.isNotEmpty) {
      final params = query.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      sb.write('?$params');
    }
    return sb.toString();
  }

  String _bucket(String? override) => override ?? bucketName;

  Future<StringResponse> _signedGet(
    String bucket,
    String resource, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final auth = await getAuth();
    final req = HttpRequest.get(_url(bucket, resource, query));
    auth.sign(req, bucket, resource);
    return _http.get(
      req.url,
      headers: req.headers,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // ==================== Object Operations ====================

  @override
  Future<PutObjectResult> putObject(PutObjectRequest request,
      {CancelToken? cancelToken}) async {
    final bucket = request.bucketName ?? bucketName;
    final auth = await getAuth();
    final mf = MultipartFile.fromBytes(request.data, filename: request.key);
    final headers = <String, dynamic>{
      'content-type': contentType(request.key),
      'content-length': mf.length,
      'x-oss-forbid-overwrite': !(request.override ?? true),
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      'x-oss-storage-class':
          (request.storageType ?? StorageType.standard).content,
      ...?request.headers,
      if (request.callback != null) ...request.callback!.toHeaders(),
    };
    final url = 'https://$bucket.$endpoint/${request.key}';
    final httpReq = HttpRequest.put(url, headers: headers);
    auth.sign(httpReq, bucket, request.key);
    final resp = await _http.put(
      httpReq.url,
      body: mf.stream,
      contentLength: mf.length,
      headers: httpReq.headers,
      cancelToken: cancelToken,
      onSendProgress: request.onSendProgress,
    );
    return PutObjectResult.fromOssResponse(resp);
  }

  @override
  Future<PutObjectResult> putObjectFile(
    PutObjectFileRequest request, {
    CancelToken? cancelToken,
  }) async {
    final bucket = request.bucketName ?? bucketName;
    final filename =
        request.key ?? request.filepath.split(Platform.pathSeparator).last;
    final auth = await getAuth();
    final mf =
        await MultipartFile.fromFile(request.filepath, filename: filename);
    final headers = <String, dynamic>{
      'content-type': contentType(filename),
      'content-length': mf.length,
      'x-oss-forbid-overwrite': !(request.override ?? true),
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      'x-oss-storage-class':
          (request.storageType ?? StorageType.standard).content,
      ...?request.headers,
      if (request.callback != null) ...request.callback!.toHeaders(),
    };
    final url = 'https://$bucket.$endpoint/$filename';
    final httpReq = HttpRequest.put(url, headers: headers);
    auth.sign(httpReq, bucket, filename);
    final resp = await _http.put(
      httpReq.url,
      body: mf.stream,
      contentLength: mf.length,
      headers: httpReq.headers,
      cancelToken: cancelToken,
      onSendProgress: request.onSendProgress,
    );
    return PutObjectResult.fromOssResponse(resp);
  }

  @override
  Future<List<PutObjectResult>> putObjectFiles(
    PutObjectFilesRequest request, {
    CancelToken? cancelToken,
  }) async {
    if (request.files.isEmpty) return [];
    final results = <PutObjectResult>[];
    final total = request.files.length;
    var completed = 0;
    for (final chunk in _fileChunks(request.files, request.parallel)) {
      final uploaded = await Future.wait(
        chunk.map(
          (item) => _uploadBatchFile(
            item,
            cancelToken: cancelToken,
            total: total,
            onProgress: request.onProgress,
            complete: () => completed += 1,
          ),
        ),
      );
      results.addAll(uploaded);
    }
    return results;
  }

  Future<PutObjectResult> _uploadBatchFile(
    PutObjectFileRequest request, {
    CancelToken? cancelToken,
    required int total,
    BatchUploadProgressCallback? onProgress,
    required int Function() complete,
  }) async {
    final result = await putObjectFile(request, cancelToken: cancelToken);
    final completed = complete();
    onProgress?.call(completed, total);
    return result;
  }

  @override
  Future<UploadFileResult> uploadFile(
    UploadFileRequest request, {
    CancelToken? cancelToken,
  }) async {
    final file = File(request.filepath);
    final key = _uploadKey(request.filepath, request.key);
    final size = await file.length();
    final mode = request.modeFor(size);
    if (mode == UploadMode.simple) {
      return _putAutoFile(request, key, cancelToken);
    }
    return _multipartAutoFile(request, cancelToken);
  }

  Future<UploadFileResult> _putAutoFile(
    UploadFileRequest request,
    String key,
    CancelToken? cancelToken,
  ) async {
    final result = await putObjectFile(
      request.toPutRequest(),
      cancelToken: cancelToken,
    );
    final bucket = _bucket(request.bucketName);
    return UploadFileResult.fromPutObject(
      bucket,
      key,
      _objectUrl(bucket, key),
      result,
    );
  }

  Future<UploadFileResult> _multipartAutoFile(
    UploadFileRequest request,
    CancelToken? cancelToken,
  ) async {
    final result = await multipartUploadFile(
      request.toMultipartRequest(),
      cancelToken: cancelToken,
    );
    return UploadFileResult.fromMultipart(result);
  }

  @override
  Future<List<UploadFileResult>> uploadFiles(
    UploadFilesRequest request, {
    CancelToken? cancelToken,
  }) async {
    if (request.files.isEmpty) return [];
    final results = <UploadFileResult>[];
    final total = request.files.length;
    var completed = 0;
    for (final chunk in _uploadFileChunks(request.files, request.parallel)) {
      final uploaded = await Future.wait(
        chunk.map(
          (item) => _uploadAutoBatchFile(
            item,
            cancelToken: cancelToken,
            total: total,
            onProgress: request.onProgress,
            complete: () => completed += 1,
          ),
        ),
      );
      results.addAll(uploaded);
    }
    return results;
  }

  Iterable<List<UploadFileRequest>> _uploadFileChunks(
    List<UploadFileRequest> files,
    int parallel,
  ) sync* {
    final size = _parallelCount(parallel);
    for (var index = 0; index < files.length; index += size) {
      yield files.sublist(index, math.min(index + size, files.length));
    }
  }

  Future<UploadFileResult> _uploadAutoBatchFile(
    UploadFileRequest request, {
    CancelToken? cancelToken,
    required int total,
    MultipartBatchUploadProgressCallback? onProgress,
    required int Function() complete,
  }) async {
    final result = await uploadFile(request, cancelToken: cancelToken);
    final completed = complete();
    onProgress?.call(completed, total);
    return result;
  }

  Iterable<List<PutObjectFileRequest>> _fileChunks(
    List<PutObjectFileRequest> files,
    int parallel,
  ) sync* {
    final size = _parallelCount(parallel);
    for (var index = 0; index < files.length; index += size) {
      yield files.sublist(index, math.min(index + size, files.length));
    }
  }

  int _parallelCount(int parallel) => parallel < 1 ? 1 : parallel;

  String _bucketUrl(String bucket) => 'https://$bucket.$endpoint';

  String _objectUrl(String bucket, String key) =>
      'https://$bucket.$endpoint/$key';

  @override
  Future<InitiateMultipartUploadResult> initiateMultipartUpload(
    InitiateMultipartUploadRequest request, {
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(request.bucketName);
    final auth = await getAuth();
    final httpReq = HttpRequest.post(
      _objectUrl(bucket, request.key),
      parameters: _initiateParameters(request),
      headers: _initiateHeaders(request),
    );
    auth.sign(httpReq, bucket, request.key);
    final resp = await _http.post(
      httpReq.url,
      headers: httpReq.headers,
      cancelToken: cancelToken,
    );
    return InitiateMultipartUploadResult.fromXml(XmlDocument.parse(resp.data));
  }

  Map<String, dynamic> _initiateParameters(
    InitiateMultipartUploadRequest request,
  ) {
    return {
      'uploads': '',
      if (request.encodingType != null) 'encoding-type': request.encodingType,
    };
  }

  Map<String, dynamic> _initiateHeaders(
    InitiateMultipartUploadRequest request,
  ) {
    return {
      'content-type': contentType(request.key),
      'x-oss-forbid-overwrite': !(request.override ?? true),
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      'x-oss-storage-class':
          (request.storageType ?? StorageType.standard).content,
      ...?request.headers,
    };
  }

  @override
  Future<UploadPartResult> uploadPart(
    UploadPartRequest request, {
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(request.bucketName);
    final auth = await getAuth();
    final part = MultipartFile.fromBytes(request.data, filename: request.key);
    final httpReq = HttpRequest.put(
      _objectUrl(bucket, request.key),
      parameters: _uploadPartParameters(request),
      headers: _uploadPartHeaders(request, part.length),
    );
    auth.sign(httpReq, bucket, request.key);
    final resp = await _http.put(
      httpReq.url,
      body: part.stream,
      contentLength: part.length,
      headers: httpReq.headers,
      cancelToken: cancelToken,
      onSendProgress: request.onSendProgress,
    );
    return UploadPartResult.fromOssResponse(request.partNumber, resp);
  }

  Map<String, dynamic> _uploadPartParameters(UploadPartRequest request) {
    return {
      'partNumber': request.partNumber,
      'uploadId': request.uploadId,
    };
  }

  Map<String, dynamic> _uploadPartHeaders(
    UploadPartRequest request,
    int contentLength,
  ) {
    return {
      'content-length': contentLength,
      ...?request.headers,
    };
  }

  @override
  Future<CompleteMultipartUploadResult> completeMultipartUpload(
    CompleteMultipartUploadRequest request, {
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(request.bucketName);
    final auth = await getAuth();
    final body = utf8.encode(_completeMultipartBody(request.parts));
    final httpReq = HttpRequest.post(
      _objectUrl(bucket, request.key),
      parameters: _completeParameters(request),
      headers: _completeHeaders(request, body.length),
    );
    auth.sign(httpReq, bucket, request.key);
    final resp = await _http.post(
      httpReq.url,
      body: Stream.fromIterable([body]),
      contentLength: body.length,
      headers: httpReq.headers,
      cancelToken: cancelToken,
    );
    return _completeResult(resp);
  }

  Map<String, dynamic> _completeParameters(
    CompleteMultipartUploadRequest request,
  ) {
    return {
      'uploadId': request.uploadId,
      if (request.encodingType != null) 'encoding-type': request.encodingType,
    };
  }

  Map<String, dynamic> _completeHeaders(
    CompleteMultipartUploadRequest request,
    int length,
  ) {
    return {
      'content-type': 'application/xml',
      'content-length': length,
      'x-oss-forbid-overwrite': !(request.override ?? true),
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      ...?request.headers,
    };
  }

  String _completeMultipartBody(List<UploadedPart> parts) {
    final sorted = [...parts]
      ..sort((a, b) => a.partNumber.compareTo(b.partNumber));
    final builder = XmlBuilder();
    builder.element('CompleteMultipartUpload', nest: () {
      for (final part in sorted) {
        builder.element('Part', nest: () {
          builder.element('PartNumber', nest: part.partNumber);
          builder.element('ETag', nest: part.eTag);
        });
      }
    });
    return builder.buildDocument().toXmlString();
  }

  CompleteMultipartUploadResult _completeResult(StringResponse response) {
    final xml = XmlDocument.parse(response.data);
    return CompleteMultipartUploadResult.fromXml(xml, response.headers);
  }

  @override
  Future<void> abortMultipartUpload(
    String key,
    String uploadId, {
    String? bucketName,
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final httpReq = HttpRequest.delete(
      _objectUrl(bucket, key),
      parameters: {'uploadId': uploadId},
    );
    auth.sign(httpReq, bucket, key);
    await _http.delete(
      httpReq.url,
      headers: httpReq.headers,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ListMultipartUploadsResult> listMultipartUploads(
    ListMultipartUploadsRequest request, {
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(request.bucketName);
    final auth = await getAuth();
    final httpReq = HttpRequest.get(
      _bucketUrl(bucket),
      parameters: _listMultipartUploadsParameters(request),
    );
    auth.sign(httpReq, bucket, '');
    final resp = await _http.get(
      httpReq.url,
      headers: httpReq.headers,
      cancelToken: cancelToken,
    );
    return ListMultipartUploadsResult.fromXml(XmlDocument.parse(resp.data));
  }

  Map<String, dynamic> _listMultipartUploadsParameters(
    ListMultipartUploadsRequest request,
  ) {
    return {
      'uploads': '',
      if (request.prefix != null) 'prefix': request.prefix,
      if (request.delimiter != null) 'delimiter': request.delimiter,
      if (request.keyMarker != null) 'key-marker': request.keyMarker,
      if (request.uploadIdMarker != null)
        'upload-id-marker': request.uploadIdMarker,
      if (request.maxUploads != null) 'max-uploads': request.maxUploads,
      if (request.encodingType != null) 'encoding-type': request.encodingType,
    };
  }

  @override
  Future<ListPartsResult> listParts(
    ListPartsRequest request, {
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(request.bucketName);
    final auth = await getAuth();
    final httpReq = HttpRequest.get(
      _objectUrl(bucket, request.key),
      parameters: _listPartsParameters(request),
    );
    auth.sign(httpReq, bucket, request.key);
    final resp = await _http.get(
      httpReq.url,
      headers: httpReq.headers,
      cancelToken: cancelToken,
    );
    return ListPartsResult.fromXml(XmlDocument.parse(resp.data));
  }

  Map<String, dynamic> _listPartsParameters(ListPartsRequest request) {
    return {
      'uploadId': request.uploadId,
      if (request.maxParts != null) 'max-parts': request.maxParts,
      if (request.partNumberMarker != null)
        'part-number-marker': request.partNumberMarker,
      if (request.encodingType != null) 'encoding-type': request.encodingType,
    };
  }

  @override
  Future<CompleteMultipartUploadResult> multipartUploadFile(
    MultipartUploadFileRequest request, {
    CancelToken? cancelToken,
  }) async {
    final key = _multipartKey(request);
    final file = File(request.filepath);
    final bucket = _bucket(request.bucketName);
    final length = await file.length();
    if (length == 0) return _putEmptyMultipartFile(request, key, cancelToken);
    final partSize = _partSize(request.partSize);
    final plan = await _multipartPlan(
      request,
      bucket,
      key,
      file,
      partSize,
      cancelToken,
    );
    try {
      final result = await _uploadMultipartFile(
        request,
        key,
        file,
        length,
        plan,
        partSize,
        cancelToken,
      );
      await _checkpoints.delete(plan.checkpoint);
      return result;
    } catch (_) {
      await _handleMultipartFailure(request, key, plan.uploadId, cancelToken);
      rethrow;
    }
  }

  @override
  Future<List<CompleteMultipartUploadResult>> multipartUploadFiles(
    MultipartUploadFilesRequest request, {
    CancelToken? cancelToken,
  }) async {
    if (request.files.isEmpty) return [];
    final results = <CompleteMultipartUploadResult>[];
    final total = request.files.length;
    var completed = 0;
    for (final chunk in _multipartFileChunks(request.files, request.parallel)) {
      final uploaded = await Future.wait(
        chunk.map(
          (item) => _uploadMultipartBatchFile(
            item,
            cancelToken: cancelToken,
            total: total,
            onProgress: request.onProgress,
            complete: () => completed += 1,
          ),
        ),
      );
      results.addAll(uploaded);
    }
    return results;
  }

  Iterable<List<MultipartUploadFileRequest>> _multipartFileChunks(
    List<MultipartUploadFileRequest> files,
    int parallel,
  ) sync* {
    final size = _parallelCount(parallel);
    for (var index = 0; index < files.length; index += size) {
      yield files.sublist(index, math.min(index + size, files.length));
    }
  }

  Future<CompleteMultipartUploadResult> _uploadMultipartBatchFile(
    MultipartUploadFileRequest request, {
    CancelToken? cancelToken,
    required int total,
    MultipartBatchUploadProgressCallback? onProgress,
    required int Function() complete,
  }) async {
    final result = await multipartUploadFile(
      request,
      cancelToken: cancelToken,
    );
    final completed = complete();
    onProgress?.call(completed, total);
    return result;
  }

  String _multipartKey(MultipartUploadFileRequest request) {
    return _uploadKey(request.filepath, request.key);
  }

  String _uploadKey(String filepath, String? key) {
    return key ?? filepath.split(Platform.pathSeparator).last;
  }

  Future<_MultipartUploadPlan> _multipartPlan(
    MultipartUploadFileRequest request,
    String bucket,
    String key,
    File file,
    int partSize,
    CancelToken? cancelToken,
  ) async {
    final checkpoint = await _checkpoints.load(request, bucket, key, file);
    if (checkpoint != null) return _planFromCheckpoint(checkpoint);
    return _newMultipartPlan(request, bucket, key, file, partSize, cancelToken);
  }

  _MultipartUploadPlan _planFromCheckpoint(
    MultipartUploadCheckpoint checkpoint,
  ) {
    return _MultipartUploadPlan(
      uploadId: checkpoint.uploadId,
      parts: checkpoint.parts,
      checkpoint: checkpoint,
    );
  }

  Future<_MultipartUploadPlan> _newMultipartPlan(
    MultipartUploadFileRequest request,
    String bucket,
    String key,
    File file,
    int partSize,
    CancelToken? cancelToken,
  ) async {
    final upload = await _startMultipartUpload(request, key, cancelToken);
    final checkpoint = await _checkpoints.create(
      request,
      bucket,
      key,
      file,
      upload.uploadId,
      partSize,
    );
    return _MultipartUploadPlan(
      uploadId: upload.uploadId,
      parts: const [],
      checkpoint: checkpoint,
    );
  }

  Future<InitiateMultipartUploadResult> _startMultipartUpload(
    MultipartUploadFileRequest request,
    String key,
    CancelToken? cancelToken,
  ) {
    return initiateMultipartUpload(
      InitiateMultipartUploadRequest(
        key: key,
        bucketName: request.bucketName,
        aclMode: request.aclMode,
        storageType: request.storageType,
        override: request.override,
        headers: request.headers,
      ),
      cancelToken: cancelToken,
    );
  }

  Future<CompleteMultipartUploadResult> _putEmptyMultipartFile(
    MultipartUploadFileRequest request,
    String key,
    CancelToken? cancelToken,
  ) async {
    final result = await putObjectFile(
      PutObjectFileRequest(
        filepath: request.filepath,
        key: key,
        bucketName: request.bucketName,
        aclMode: request.aclMode,
        storageType: request.storageType,
        override: request.override,
        headers: request.headers,
        onSendProgress: request.onSendProgress,
      ),
      cancelToken: cancelToken,
    );
    return _putResultToMultipartResult(request, key, result);
  }

  CompleteMultipartUploadResult _putResultToMultipartResult(
    MultipartUploadFileRequest request,
    String key,
    PutObjectResult result,
  ) {
    final bucket = _bucket(request.bucketName);
    return CompleteMultipartUploadResult(
      location: _objectUrl(bucket, key),
      bucket: bucket,
      key: key,
      eTag: result.eTag,
      versionId: result.versionId,
    );
  }

  Future<CompleteMultipartUploadResult> _uploadMultipartFile(
    MultipartUploadFileRequest request,
    String key,
    File file,
    int length,
    _MultipartUploadPlan plan,
    int partSize,
    CancelToken? cancelToken,
  ) async {
    final parts = await _uploadMultipartParts(
      request,
      key,
      file,
      length,
      plan,
      partSize,
      cancelToken,
    );
    return completeMultipartUpload(
      CompleteMultipartUploadRequest(
        key: key,
        uploadId: plan.uploadId,
        parts: parts,
        bucketName: request.bucketName,
        override: request.override,
        aclMode: request.aclMode,
      ),
      cancelToken: cancelToken,
    );
  }

  Future<List<UploadedPart>> _uploadMultipartParts(
    MultipartUploadFileRequest request,
    String key,
    File file,
    int length,
    _MultipartUploadPlan plan,
    int partSize,
    CancelToken? cancelToken,
  ) async {
    final tracker = _MultipartProgressTracker(
      total: length,
      baseSent: _uploadedBytes(plan.parts),
      onSendProgress: request.onSendProgress,
      onPartProgress: request.onPartProgress,
    );
    final parts = [...plan.parts];
    final sink = _CheckpointSink(_checkpoints, plan.checkpoint);
    for (final chunk in _pendingPartChunks(length, partSize, request, parts)) {
      final uploaded = await Future.wait(
        chunk.map(
          (partNumber) => _uploadSinglePart(
            request,
            key,
            file,
            length,
            plan.uploadId,
            partNumber,
            partSize,
            tracker,
            sink,
            cancelToken,
          ),
        ),
      );
      parts.addAll(uploaded);
    }
    parts.sort((a, b) => a.partNumber.compareTo(b.partNumber));
    return parts;
  }

  int _partSize(int partSize) => partSize < 100 * 1024 ? 100 * 1024 : partSize;

  int _uploadedBytes(List<UploadedPart> parts) {
    return parts.fold(0, (sum, item) => sum + (item.size ?? 0));
  }

  Iterable<List<int>> _pendingPartChunks(
    int length,
    int partSize,
    MultipartUploadFileRequest request,
    List<UploadedPart> parts,
  ) sync* {
    final completed = parts.map((item) => item.partNumber).toSet();
    final pending = _partNumbers(length, partSize, request.parallel)
        .map((chunk) =>
            chunk.where((item) => !completed.contains(item)).toList())
        .where((chunk) => chunk.isNotEmpty);
    yield* pending;
  }

  Iterable<List<int>> _partNumbers(
      int length, int partSize, int parallel) sync* {
    final count = _partCount(length, partSize);
    final size = _parallelCount(parallel);
    for (var start = 1; start <= count; start += size) {
      final end = math.min(start + size - 1, count);
      yield [for (var current = start; current <= end; current++) current];
    }
  }

  int _partCount(int length, int partSize) => (length / partSize).ceil();

  Future<UploadedPart> _uploadSinglePart(
    MultipartUploadFileRequest request,
    String key,
    File file,
    int length,
    String uploadId,
    int partNumber,
    int partSize,
    _MultipartProgressTracker tracker,
    _CheckpointSink sink,
    CancelToken? cancelToken,
  ) async {
    final bytes = await _readPartBytes(file, length, partNumber, partSize);
    final part = await uploadPart(
      UploadPartRequest(
        key: key,
        uploadId: uploadId,
        partNumber: partNumber,
        data: bytes,
        bucketName: request.bucketName,
        onSendProgress: (count, total) =>
            tracker.track(partNumber, count, total),
      ),
      cancelToken: cancelToken,
    );
    final uploaded = UploadedPart(
      partNumber: part.partNumber,
      eTag: part.eTag,
      size: bytes.length,
    );
    await sink.save(uploaded);
    return uploaded;
  }

  Future<List<int>> _readPartBytes(
    File file,
    int length,
    int partNumber,
    int partSize,
  ) {
    final (start, end) = _partRange(length, partNumber, partSize);
    return file.openRead(start, end).expand((chunk) => chunk).toList();
  }

  (int, int) _partRange(int length, int partNumber, int partSize) {
    final start = (partNumber - 1) * partSize;
    final end = math.min(start + partSize, length);
    return (start, end);
  }

  Future<void> _abortQuietly(
    String key,
    String uploadId,
    String? bucketName,
    CancelToken? cancelToken,
  ) async {
    try {
      await abortMultipartUpload(
        key,
        uploadId,
        bucketName: bucketName,
        cancelToken: cancelToken,
      );
    } catch (_) {}
  }

  Future<void> _handleMultipartFailure(
    MultipartUploadFileRequest request,
    String key,
    String uploadId,
    CancelToken? cancelToken,
  ) async {
    if (request.resumable) return;
    await _abortQuietly(key, uploadId, request.bucketName, cancelToken);
  }

  @override
  Future<AppendObjectResult> appendObject(
    AppendObjectRequest request, {
    CancelToken? cancelToken,
  }) async {
    final bucket = request.bucketName ?? bucketName;
    final auth = await getAuth();
    final mf = MultipartFile.fromBytes(request.data, filename: request.key);
    final pos = request.position ?? 0;
    final headers = <String, dynamic>{
      'content-type': contentType(request.key),
      'content-length': mf.length,
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      'x-oss-storage-class':
          (request.storageType ?? StorageType.standard).content,
      ...?request.headers,
    };
    final url = 'https://$bucket.$endpoint/${request.key}?append&position=$pos';
    final httpReq = HttpRequest.post(url, headers: headers);
    auth.sign(httpReq, bucket, '${request.key}?append&position=$pos');
    final resp = await _http.post(
      httpReq.url,
      body: mf.stream,
      contentLength: mf.length,
      headers: httpReq.headers,
      cancelToken: cancelToken,
      onSendProgress: request.onSendProgress,
    );
    return AppendObjectResult.fromOssResponse(resp);
  }

  @override
  Future<CopyObjectResult> copyObject(CopyObjectRequest request,
      {CancelToken? cancelToken}) async {
    final sourceBucket = request.sourceBucketName ?? bucketName;
    final targetBucket = request.targetBucketName ?? sourceBucket;
    final copySource = '/$sourceBucket/${request.sourceKey}';
    final headers = <String, dynamic>{
      'content-type': contentType(request.targetKey),
      'x-oss-copy-source': copySource,
      'x-oss-forbid-overwrite': !(request.override ?? true),
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      'x-oss-storage-class':
          (request.storageType ?? StorageType.standard).content,
      ...?request.headers,
    };
    final auth = await getAuth();
    final url = 'https://$targetBucket.$endpoint/${request.targetKey}';
    final httpReq = HttpRequest.put(url, headers: headers);
    auth.sign(httpReq, targetBucket, request.targetKey);
    final resp = await _http.put(
      httpReq.url,
      headers: httpReq.headers,
      cancelToken: cancelToken,
    );
    if (resp.data.isNotEmpty) {
      return CopyObjectResult.fromXml(XmlDocument.parse(resp.data));
    }
    return CopyObjectResult.fromResponse(resp.statusCode, resp.headers);
  }

  @override
  Future<BytesResponse> getObject(GetObjectRequest request,
      {CancelToken? cancelToken}) async {
    final bucket = _bucket(request.bucketName);
    final auth = await getAuth();
    final query = request.toParameters();
    final base = request.key;
    final url = _url(bucket, base, query);
    final httpReq = HttpRequest.get(url);
    auth.sign(httpReq, bucket, base);
    httpReq.headers.addAll(request.toHeaders());
    return _http.getBytes(
      httpReq.url,
      headers: httpReq.headers,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ObjectMeta> getObjectMeta(
    String key, {
    String? bucketName,
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final req = HttpRequest.head('https://$bucket.$endpoint/$key');
    auth.sign(req, bucket, key);
    final resp = await _http.head(
      req.url,
      headers: req.headers,
      cancelToken: cancelToken,
    );
    return ObjectMeta.fromOssResponse(resp);
  }

  @override
  Future<bool> doesObjectExist(
    String key, {
    String? bucketName,
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final req = HttpRequest.head('https://$bucket.$endpoint/$key');
    auth.sign(req, bucket, key);
    try {
      await _http.head(req.url, headers: req.headers, cancelToken: cancelToken);
      return true;
    } on OssException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    }
  }

  @override
  Future<EmptyResponse> downloadObject(
    String key,
    String savePath, {
    String? bucketName,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final req = HttpRequest.get('https://$bucket.$endpoint/$key');
    auth.sign(req, bucket, key);
    return _http.download(
      req.url,
      savePath,
      headers: req.headers,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<DeleteObjectResult> deleteObject(
    DeleteObjectRequest request, {
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(request.bucketName);
    final auth = await getAuth();
    final req = HttpRequest.delete(
      'https://$bucket.$endpoint/${request.key}',
      headers: {'content-type': HttpMixin.jsonContentType},
    );
    auth.sign(req, bucket, request.key);
    final resp = await _http.delete(
      req.url,
      headers: req.headers,
      cancelToken: cancelToken,
    );
    return DeleteObjectResult.fromResponse(request.key, resp.statusCode);
  }

  @override
  Future<List<DeleteObjectResult>> deleteObjects(
    DeleteObjectsRequest request, {
    CancelToken? cancelToken,
  }) async {
    return Future.wait(
      request.keys.map(
        (k) => deleteObject(
          DeleteObjectRequest(key: k, bucketName: request.bucketName),
          cancelToken: cancelToken,
        ),
      ),
    );
  }

  // ==================== Signed URL Operations ====================

  @override
  Future<String> getSignedUrl(
    String key, {
    String? bucketName,
    int expireSeconds = 60,
    Map<String, dynamic>? params,
  }) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final expires = DateTime.now().secondsSinceEpoch() + expireSeconds;
    final parameters = <String, dynamic>{
      'OSSAccessKeyId': auth.accessKey,
      'Expires': expires,
      'Signature': auth.getSignature(expires, bucket, key, params: params),
      'security-token': auth.encodedToken,
      ...?params,
    };
    final req = HttpRequest.get(
      'https://$bucket.$endpoint/$key',
      parameters: parameters,
    );
    return req.url;
  }

  @override
  Future<Map<String, String>> getSignedUrls(
    List<String> keys, {
    String? bucketName,
    int expireSeconds = 60,
  }) async {
    final result = <String, String>{};
    for (final key in keys.toSet()) {
      result[key] = await getSignedUrl(
        key,
        bucketName: bucketName,
        expireSeconds: expireSeconds,
      );
    }
    return result;
  }

  // ==================== Bucket Operations ====================

  @override
  Future<ListObjectsResult> listObjects(
    ListObjectsRequest request, {
    String? bucketName,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final params = {...request.toParameters(), 'list-type': 2};
    final req =
        HttpRequest.get('https://$bucket.$endpoint', parameters: params);
    auth.sign(req, bucket, '');
    final resp = await _http.get(
      req.url,
      headers: req.headers,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    return ListObjectsResult.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<ListBucketsResult> listBuckets(
    ListBucketsRequest request, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final auth = await getAuth();
    final req = HttpRequest.get('https://$endpoint',
        parameters: request.toParameters());
    auth.sign(req, '', '');
    final resp = await _http.get(
      req.url,
      headers: req.headers,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    return ListBucketsResult.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<BucketInfo> getBucketInfo(
      {String? bucketName, CancelToken? cancelToken}) async {
    final bucket = _bucket(bucketName);
    final resp =
        await _signedGet(bucket, '?bucketInfo', cancelToken: cancelToken);
    return BucketInfo.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<BucketStat> getBucketStat(
      {String? bucketName, CancelToken? cancelToken}) async {
    final bucket = _bucket(bucketName);
    final resp = await _signedGet(bucket, '?stat', cancelToken: cancelToken);
    return BucketStat.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<BucketAcl> getBucketAcl(
      {String? bucketName, CancelToken? cancelToken}) async {
    final bucket = _bucket(bucketName);
    final resp = await _signedGet(bucket, '?acl', cancelToken: cancelToken);
    return BucketAcl.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<void> putBucketAcl(
    AclMode aclMode, {
    String? bucketName,
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final req = HttpRequest.put(
      'https://$bucket.$endpoint/?acl',
      headers: {
        'content-type': HttpMixin.jsonContentType,
        'x-oss-acl': aclMode.content,
      },
    );
    auth.sign(req, bucket, '?acl');
    await _http.put(req.url, headers: req.headers, cancelToken: cancelToken);
  }

  @override
  Future<String?> getBucketPolicy(
      {String? bucketName, CancelToken? cancelToken}) async {
    final bucket = _bucket(bucketName);
    final resp = await _signedGet(bucket, '?policy', cancelToken: cancelToken);
    return resp.data.isNotEmpty ? resp.data : null;
  }

  @override
  Future<void> putBucketPolicy(
    Map<String, dynamic> policy, {
    String? bucketName,
    CancelToken? cancelToken,
  }) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final req = HttpRequest.put(
      'https://$bucket.$endpoint/?policy',
      headers: {'content-type': HttpMixin.jsonContentType},
    );
    auth.sign(req, bucket, '?policy');
    final body = utf8.encode(jsonEncode(policy));
    await _http.put(
      req.url,
      body: Stream.fromIterable([body]),
      contentLength: body.length,
      headers: req.headers,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<void> deleteBucketPolicy(
      {String? bucketName, CancelToken? cancelToken}) async {
    final bucket = _bucket(bucketName);
    final auth = await getAuth();
    final req = HttpRequest.delete(
      'https://$bucket.$endpoint/?policy',
      headers: {'content-type': HttpMixin.jsonContentType},
    );
    auth.sign(req, bucket, '?policy');
    await _http.delete(req.url, headers: req.headers, cancelToken: cancelToken);
  }

  // ==================== Region Operations ====================

  @override
  Future<RegionsResult> getAllRegions({CancelToken? cancelToken}) async {
    final auth = await getAuth();
    final req = HttpRequest.get('https://$endpoint/?regions');
    auth.sign(req, '', '');
    final resp = await _http.get(req.url,
        headers: req.headers, cancelToken: cancelToken);
    return RegionsResult.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<RegionsResult> getRegion(String region,
      {CancelToken? cancelToken}) async {
    final auth = await getAuth();
    final req = HttpRequest.get('https://$endpoint/?regions=$region');
    auth.sign(req, '', '');
    final resp = await _http.get(req.url,
        headers: req.headers, cancelToken: cancelToken);
    return RegionsResult.fromXml(XmlDocument.parse(resp.data));
  }
}

class _MultipartProgressTracker {
  _MultipartProgressTracker({
    required this.total,
    this.baseSent = 0,
    this.onSendProgress,
    this.onPartProgress,
  });

  final int total;
  final int baseSent;
  final ProgressCallback? onSendProgress;
  final MultipartPartProgressCallback? onPartProgress;
  final Map<int, int> _partSent = <int, int>{};

  void track(int partNumber, int sent, int partTotal) {
    _partSent[partNumber] = sent;
    onPartProgress?.call(partNumber, sent, partTotal);
    onSendProgress?.call(_overallSent, total);
  }

  int get _overallSent {
    return baseSent + _partSent.values.fold(0, (sum, item) => sum + item);
  }
}

class _MultipartUploadPlan {
  const _MultipartUploadPlan({
    required this.uploadId,
    required this.parts,
    required this.checkpoint,
  });

  final String uploadId;
  final List<UploadedPart> parts;
  final MultipartUploadCheckpoint? checkpoint;
}

class _CheckpointSink {
  _CheckpointSink(this.store, this.current);

  final MultipartUploadCheckpointStore store;
  MultipartUploadCheckpoint? current;
  Future<void> _tail = Future.value();

  Future<void> save(UploadedPart part) {
    if (current == null) return Future.value();
    final next = _tail.then((_) async => current = await _next(part));
    _tail = next;
    return next;
  }

  Future<MultipartUploadCheckpoint> _next(UploadedPart part) async {
    return store.savePart(current!, part);
  }
}
