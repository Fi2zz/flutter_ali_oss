import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'cancel_token.dart';
import 'oss_response.dart';

/// A lightweight HTTP client for OSS built on top of dart:io HttpClient.
class OssHttpClient {
  OssHttpClient({bool logging = false}) : _logging = logging;

  final bool _logging;
  final HttpClient _httpClient = HttpClient()..autoUncompress = false;

  Future<StringResponse> get(
    String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onReceiveProgress,
  }) async {
    return _request('GET', url, headers: headers, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
  }

  Future<BytesResponse> getBytes(
    String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onReceiveProgress,
  }) async {
    return _requestBytes('GET', url, headers: headers, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
  }

  Future<OssResponse<void>> head(
    String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    cancelToken?.throwIfCancelled();
    final request = await _httpClient.openUrl('HEAD', Uri.parse(url));
    _applyHeaders(request, headers);
    if (_logging) _logRequest('HEAD', url, headers);
    final response = await request.close();
    cancelToken?.throwIfCancelled();
    final h = _extractHeaders(response);
    await response.drain<void>();
    return OssResponse<void>(data: null, statusCode: response.statusCode, headers: h, requestId: h['x-oss-request-id']);
  }

  Future<StringResponse> put(
    String url, {
    Stream<List<int>>? body,
    int? contentLength,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    return _request('PUT', url, body: body, contentLength: contentLength, headers: headers, cancelToken: cancelToken, onSendProgress: onSendProgress);
  }

  Future<StringResponse> post(
    String url, {
    Stream<List<int>>? body,
    int? contentLength,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    return _request('POST', url, body: body, contentLength: contentLength, headers: headers, cancelToken: cancelToken, onSendProgress: onSendProgress);
  }

  Future<OssResponse<void>> delete(
    String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    cancelToken?.throwIfCancelled();
    final request = await _httpClient.openUrl('DELETE', Uri.parse(url));
    _applyHeaders(request, headers);
    if (_logging) _logRequest('DELETE', url, headers);
    final response = await request.close();
    cancelToken?.throwIfCancelled();
    final bodyBytes = await response.expand((c) => c).toList();
    final h = _extractHeaders(response);
    if (_logging) _logResponse(response.statusCode, h, utf8.decode(bodyBytes, allowMalformed: true));
    return OssResponse<void>(data: null, statusCode: response.statusCode, headers: h, requestId: h['x-oss-request-id']);
  }

  Future<OssResponse<void>> download(
    String url,
    String savePath, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    cancelToken?.throwIfCancelled();
    final request = await _httpClient.openUrl('GET', Uri.parse(url));
    _applyHeaders(request, headers);
    if (_logging) _logRequest('GET download', url, headers);
    final response = await request.close();
    cancelToken?.throwIfCancelled();
    final h = _extractHeaders(response);
    final total = int.tryParse(h['content-length'] ?? '') ?? 0;
    final file = File(savePath);
    await file.create(recursive: true);
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response) {
        cancelToken?.throwIfCancelled();
        sink.add(chunk);
        received += chunk.length;
        if (onReceiveProgress != null && total > 0) onReceiveProgress(received, total);
      }
    } finally {
      await sink.close();
    }
    return OssResponse<void>(data: null, statusCode: response.statusCode, headers: h, requestId: h['x-oss-request-id']);
  }

  // Internal helpers

  Future<StringResponse> _request(
    String method,
    String url, {
    Stream<List<int>>? body,
    int? contentLength,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    cancelToken?.throwIfCancelled();
    final request = await _httpClient.openUrl(method, Uri.parse(url));
    _applyHeaders(request, headers);
    if (contentLength != null) request.contentLength = contentLength;
    if (_logging) _logRequest(method, url, headers);

    if (body != null) {
      var sent = 0;
      await for (final chunk in body) {
        cancelToken?.throwIfCancelled();
        request.add(chunk);
        sent += chunk.length;
        if (onSendProgress != null && contentLength != null && contentLength > 0) onSendProgress(sent, contentLength);
      }
    }

    final response = await request.close();
    cancelToken?.throwIfCancelled();
    final bytes = await response.expand((c) => c).toList();
    final h = _extractHeaders(response);
    final data = utf8.decode(bytes, allowMalformed: true);
    if (_logging) _logResponse(response.statusCode, h, data);
    return StringResponse(data: data, statusCode: response.statusCode, headers: h, requestId: h['x-oss-request-id']);
  }

  Future<BytesResponse> _requestBytes(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    cancelToken?.throwIfCancelled();
    final request = await _httpClient.openUrl(method, Uri.parse(url));
    _applyHeaders(request, headers);
    if (_logging) _logRequest('$method bytes', url, headers);
    final response = await request.close();
    cancelToken?.throwIfCancelled();
    final contentLength = int.tryParse(response.headers.value(HttpHeaders.contentLengthHeader) ?? '') ?? 0;
    final chunks = <int>[];
    await for (final chunk in response) {
      cancelToken?.throwIfCancelled();
      chunks.addAll(chunk);
      if (onReceiveProgress != null && contentLength > 0) onReceiveProgress(chunks.length, contentLength);
    }
    final h = _extractHeaders(response);
    return BytesResponse(data: chunks, statusCode: response.statusCode, headers: h, requestId: h['x-oss-request-id']);
  }

  void _applyHeaders(HttpClientRequest request, Map<String, dynamic>? headers) {
    if (headers == null) return;
    headers.forEach((key, value) {
      if (value != null) request.headers.set(key, value.toString());
    });
  }

  Map<String, String> _extractHeaders(HttpClientResponse response) {
    final map = <String, String>{};
    response.headers.forEach((name, values) => map[name.toLowerCase()] = values.join(', '));
    return map;
  }

  void _logRequest(String method, String url, Map<String, dynamic>? headers) {
    print('[OSS] $method $url');
    if (headers != null) print('[OSS] Headers: $headers');
  }

  void _logResponse(int code, Map<String, String> headers, String body) {
    print('[OSS] Response $code');
    final display = body.length > 500 ? '${body.substring(0, 500)}...' : body;
    print('[OSS] Body: $display');
  }
}
