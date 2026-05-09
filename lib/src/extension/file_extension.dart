import 'dart:typed_data';

import '../util/multipart_file.dart';

extension MultipartFileExtension on MultipartFile {
  /// Split the file stream into 64 KB chunks for streaming upload.
  Stream<List<int>> chunk() async* {
    var offset = 0;
    final bytes = await readAsBytes();
    const chunkSize = 64 * 1024;
    while (offset < bytes.length) {
      final end = (offset + chunkSize < bytes.length) ? offset + chunkSize : bytes.length;
      yield Uint8List.fromList(bytes.sublist(offset, end));
      offset = end;
    }
  }
}
