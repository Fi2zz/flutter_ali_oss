import 'dart:convert';
import 'dart:io';

import '../model/request/multipart_upload_request.dart';

class MultipartUploadCheckpoint {
  const MultipartUploadCheckpoint({
    required this.path,
    required this.filepath,
    required this.bucketName,
    required this.key,
    required this.uploadId,
    required this.fileSize,
    required this.lastModifiedMillis,
    required this.partSize,
    required this.parts,
  });

  final String path;
  final String filepath;
  final String bucketName;
  final String key;
  final String uploadId;
  final int fileSize;
  final int lastModifiedMillis;
  final int partSize;
  final List<UploadedPart> parts;

  MultipartUploadCheckpoint copyWith({
    String? uploadId,
    List<UploadedPart>? parts,
  }) {
    return MultipartUploadCheckpoint(
      path: path,
      filepath: filepath,
      bucketName: bucketName,
      key: key,
      uploadId: uploadId ?? this.uploadId,
      fileSize: fileSize,
      lastModifiedMillis: lastModifiedMillis,
      partSize: partSize,
      parts: parts ?? this.parts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filepath': filepath,
      'bucketName': bucketName,
      'key': key,
      'uploadId': uploadId,
      'fileSize': fileSize,
      'lastModifiedMillis': lastModifiedMillis,
      'partSize': partSize,
      'parts': parts.map(_partJson).toList(),
    };
  }

  factory MultipartUploadCheckpoint.fromJson(
    String path,
    Map<String, dynamic> json,
  ) {
    final partList = (json['parts'] as List<dynamic>? ?? []).cast<Map>();
    return MultipartUploadCheckpoint(
      path: path,
      filepath: json['filepath'] as String? ?? '',
      bucketName: json['bucketName'] as String? ?? '',
      key: json['key'] as String? ?? '',
      uploadId: json['uploadId'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      lastModifiedMillis: json['lastModifiedMillis'] as int? ?? 0,
      partSize: json['partSize'] as int? ?? 0,
      parts: partList.map(_partFromJson).toList(),
    );
  }

  static Map<String, dynamic> _partJson(UploadedPart part) {
    return {
      'partNumber': part.partNumber,
      'eTag': part.eTag,
      'size': part.size,
    };
  }

  static UploadedPart _partFromJson(Map<dynamic, dynamic> json) {
    return UploadedPart(
      partNumber: json['partNumber'] as int? ?? 0,
      eTag: json['eTag'] as String? ?? '',
      size: json['size'] as int?,
    );
  }
}

class MultipartUploadCheckpointStore {
  const MultipartUploadCheckpointStore();

  Future<MultipartUploadCheckpoint?> load(
    MultipartUploadFileRequest request,
    String bucketName,
    String key,
    File file,
  ) async {
    final path = _path(request, bucketName, key);
    if (path == null) return null;
    final checkpointFile = File(path);
    if (!await checkpointFile.exists()) return null;
    final json = jsonDecode(await checkpointFile.readAsString());
    final checkpoint = MultipartUploadCheckpoint.fromJson(path, json);
    if (await _valid(checkpoint, file, bucketName, key)) return checkpoint;
    await checkpointFile.delete();
    return null;
  }

  Future<MultipartUploadCheckpoint?> create(
    MultipartUploadFileRequest request,
    String bucketName,
    String key,
    File file,
    String uploadId,
    int partSize,
  ) async {
    final path = _path(request, bucketName, key);
    if (path == null) return null;
    final stat = await file.stat();
    final checkpoint = MultipartUploadCheckpoint(
      path: path,
      filepath: request.filepath,
      bucketName: bucketName,
      key: key,
      uploadId: uploadId,
      fileSize: stat.size,
      lastModifiedMillis: stat.modified.millisecondsSinceEpoch,
      partSize: partSize,
      parts: const [],
    );
    await save(checkpoint);
    return checkpoint;
  }

  Future<MultipartUploadCheckpoint> savePart(
    MultipartUploadCheckpoint checkpoint,
    UploadedPart part,
  ) async {
    final parts = _mergeParts(checkpoint.parts, part);
    final next = checkpoint.copyWith(parts: parts);
    await save(next);
    return next;
  }

  Future<void> save(MultipartUploadCheckpoint checkpoint) async {
    final file = File(checkpoint.path);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(checkpoint.toJson()));
  }

  Future<void> delete(MultipartUploadCheckpoint? checkpoint) async {
    if (checkpoint == null) return;
    final file = File(checkpoint.path);
    if (await file.exists()) await file.delete();
  }

  String? _path(
    MultipartUploadFileRequest request,
    String bucketName,
    String key,
  ) {
    final dir = request.checkpointDir;
    if (!request.resumable || dir == null || dir.isEmpty) return null;
    final name = request.checkpointKey ?? '$bucketName/$key';
    return '$dir/${Uri.encodeComponent(name)}.multipart.json';
  }

  Future<bool> _valid(
    MultipartUploadCheckpoint checkpoint,
    File file,
    String bucketName,
    String key,
  ) async {
    final stat = await file.stat();
    if (checkpoint.filepath != file.path) return false;
    if (checkpoint.bucketName != bucketName) return false;
    if (checkpoint.key != key) return false;
    if (checkpoint.fileSize != stat.size) return false;
    return checkpoint.lastModifiedMillis ==
        stat.modified.millisecondsSinceEpoch;
  }

  List<UploadedPart> _mergeParts(List<UploadedPart> parts, UploadedPart part) {
    final map = {for (final item in parts) item.partNumber: item};
    map[part.partNumber] = part;
    final merged = map.values.toList();
    merged.sort((a, b) => a.partNumber.compareTo(b.partNumber));
    return merged;
  }
}
