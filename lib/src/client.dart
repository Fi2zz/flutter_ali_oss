// 阿里云对象存储服务（OSS）Flutter SDK
// 基于阿里云 OSS REST API 构建
// 阿里云文档: https://help.aliyun.com/zh/oss/developer-reference/overview

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'model/request/put_object_request.dart';
import 'model/result/append_object_result.dart';
import 'model/result/bucket_acl.dart';
import 'model/result/bucket_info.dart';
import 'model/result/bucket_stat.dart';
import 'model/result/copy_object_result.dart';
import 'model/result/delete_object_result.dart';
import 'model/result/list_buckets_result.dart';
import 'model/result/list_objects_result.dart';
import 'model/result/object_meta.dart';
import 'model/result/put_object_result.dart';
import 'model/result/regions_result.dart';
import 'util/cancel_token.dart';
import 'util/multipart_file.dart';
import 'util/oss_exception.dart';
import 'util/oss_http_client.dart';
import 'util/oss_response.dart';

class Client with AuthMixin, HttpMixin implements ClientApi {
  static Client? _instance;
  factory Client() => _instance!;

  final String endpoint;
  final String bucketName;
  final OssHttpClient _http;

  Client._({required this.endpoint, required this.bucketName, bool logging = false})
      : _http = OssHttpClient(logging: logging);

  static Client init({
    required String ossEndpoint,
    required String bucketName,
    required FutureOr<Auth> Function() authenticator,
    bool logging = false,
  }) {
    _instance = Client._(endpoint: ossEndpoint, bucketName: bucketName, logging: logging)
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
  Future<PutObjectResult> putObject(PutObjectRequest request, {CancelToken? cancelToken}) async {
    final bucket = request.bucketName ?? bucketName;
    final auth = await getAuth();
    final mf = MultipartFile.fromBytes(request.data, filename: request.key);
    final headers = <String, dynamic>{
      'content-type': contentType(request.key),
      'content-length': mf.length,
      'x-oss-forbid-overwrite': !(request.override ?? true),
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      'x-oss-storage-class': (request.storageType ?? StorageType.standard).content,
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
    final filename = request.key ?? request.filepath.split(Platform.pathSeparator).last;
    final auth = await getAuth();
    final mf = await MultipartFile.fromFile(request.filepath, filename: filename);
    final headers = <String, dynamic>{
      'content-type': contentType(filename),
      'content-length': mf.length,
      'x-oss-forbid-overwrite': !(request.override ?? true),
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      'x-oss-storage-class': (request.storageType ?? StorageType.standard).content,
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
      'x-oss-storage-class': (request.storageType ?? StorageType.standard).content,
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
  Future<CopyObjectResult> copyObject(CopyObjectRequest request, {CancelToken? cancelToken}) async {
    final sourceBucket = request.sourceBucketName ?? bucketName;
    final targetBucket = request.targetBucketName ?? sourceBucket;
    final copySource = '/$sourceBucket/${request.sourceKey}';
    final headers = <String, dynamic>{
      'content-type': contentType(request.targetKey),
      'x-oss-copy-source': copySource,
      'x-oss-forbid-overwrite': !(request.override ?? true),
      'x-oss-object-acl': (request.aclMode ?? AclMode.inherited).content,
      'x-oss-storage-class': (request.storageType ?? StorageType.standard).content,
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
  Future<BytesResponse> getObject(GetObjectRequest request, {CancelToken? cancelToken}) async {
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
    final req = HttpRequest.get('https://$bucket.$endpoint', parameters: params);
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
    final req = HttpRequest.get('https://$endpoint', parameters: request.toParameters());
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
  Future<BucketInfo> getBucketInfo({String? bucketName, CancelToken? cancelToken}) async {
    final bucket = _bucket(bucketName);
    final resp = await _signedGet(bucket, '?bucketInfo', cancelToken: cancelToken);
    return BucketInfo.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<BucketStat> getBucketStat({String? bucketName, CancelToken? cancelToken}) async {
    final bucket = _bucket(bucketName);
    final resp = await _signedGet(bucket, '?stat', cancelToken: cancelToken);
    return BucketStat.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<BucketAcl> getBucketAcl({String? bucketName, CancelToken? cancelToken}) async {
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
  Future<String?> getBucketPolicy({String? bucketName, CancelToken? cancelToken}) async {
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
  Future<void> deleteBucketPolicy({String? bucketName, CancelToken? cancelToken}) async {
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
    final resp = await _http.get(req.url, headers: req.headers, cancelToken: cancelToken);
    return RegionsResult.fromXml(XmlDocument.parse(resp.data));
  }

  @override
  Future<RegionsResult> getRegion(String region, {CancelToken? cancelToken}) async {
    final auth = await getAuth();
    final req = HttpRequest.get('https://$endpoint/?regions=$region');
    auth.sign(req, '', '');
    final resp = await _http.get(req.url, headers: req.headers, cancelToken: cancelToken);
    return RegionsResult.fromXml(XmlDocument.parse(resp.data));
  }
}
