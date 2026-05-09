import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'oss_exception.dart';

/// A file or byte array to be uploaded to OSS.
class MultipartFile {
  MultipartFile._({
    required this.filename,
    required this.length,
    required Stream<List<int>> stream,
  }) : _stream = stream;

  /// The file name sent to OSS.
  final String filename;

  /// The total length in bytes.
  final int length;

  final Stream<List<int>> _stream;

  /// Create from an in-memory byte array.
  factory MultipartFile.fromBytes(List<int> bytes, {required String filename}) {
    return MultipartFile._(
      filename: filename,
      length: bytes.length,
      stream: Stream.fromIterable([bytes]),
    );
  }

  /// Create from a local file path.
  static Future<MultipartFile> fromFile(String filepath, {String? filename}) async {
    final name = filename ?? filepath.split(Platform.pathSeparator).last;
    final file = File(filepath);
    if (!await file.exists()) {
      throw OssException(message: 'File not found: $filepath', statusCode: 400);
    }
    final stat = await file.stat();
    return MultipartFile._(
      filename: name,
      length: stat.size,
      stream: file.openRead(),
    );
  }

  /// The raw byte stream to send.
  Stream<List<int>> get stream => _stream;

  /// Convenience: read all bytes into memory.
  Future<List<int>> readAsBytes() => _stream.expand((c) => c).toList();

  /// Compute MD5 digest as base64 (used for Content-MD5 header).
  Future<String> md5Digest() async {
    final bytes = await readAsBytes();
    return base64Encode(md5.convert(bytes).bytes);
  }
}
