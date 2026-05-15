// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_alioss/flutter_alioss.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = "Ready";

  @override
  void initState() {
    super.initState();
    Client.init(
      ossEndpoint: "oss-cn-beijing.aliyuncs.com",
      bucketName: "bucket-name",
      authenticator: () => const Auth(
        accessKey: "your-access-key",
        accessSecret: "your-access-secret",
        secureToken: "your-security-token",
        expire: "2025-12-31T23:59:59Z",
      ),
    );
  }

  void _updateStatus(String message) {
    setState(() => _status = message);
    debugPrint(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("flutter_alioss example"),
      ),
      body: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Status: $_status",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  final bytes = "Hello World".codeUnits;
                  final PutObjectResult result = await Client().putObject(
                    PutObjectRequest(
                      key: "filename.txt",
                      data: Uint8List.fromList(bytes),
                      aclMode: AclMode.private,
                      storageType: StorageType.standard,
                      callback: const Callback(
                        callbackUrl: "callbackUrl",
                        callbackBody:
                            r'{"mimeType":${mimeType},"filepath":${object},"size":${size},"bucket":${bucket},"phone":${x:phone}}',
                        callbackVar: {"x:phone": "android"},
                        calbackBodyType: CallbackBodyType.json,
                      ),
                      onSendProgress: (count, total) {
                        if (kDebugMode) print("send: $count / $total");
                      },
                    ),
                  );
                  _updateStatus(
                      "Uploaded: ETag=${result.eTag}, Status=${result.statusCode}");
                },
                child: const Text("Upload object"),
              ),
              TextButton(
                onPressed: () async {
                  final ListObjectsResult result = await Client().listObjects(
                    const ListObjectsRequest(maxKeys: 10, prefix: "filename"),
                  );
                  final buffer =
                      StringBuffer("Objects (${result.objects.length}):\n");
                  for (final obj in result.objects) {
                    buffer.writeln("  - ${obj.key} (${obj.size} bytes)");
                  }
                  _updateStatus(buffer.toString());
                },
                child: const Text("List objects"),
              ),
              TextButton(
                onPressed: () async {
                  final ObjectMeta meta =
                      await Client().getObjectMeta("filename.txt");
                  _updateStatus(
                    "Meta: size=${meta.contentLength}, type=${meta.contentType}, modified=${meta.lastModified}",
                  );
                },
                child: const Text("Get object metadata"),
              ),
              TextButton(
                onPressed: () async {
                  final BytesResponse resp = await Client().getObject(
                    const GetObjectRequest(key: "test.txt"),
                  );
                  _updateStatus(
                      "Get object: ${resp.statusCode}, ${resp.data.length} bytes");
                },
                child: const Text("Get object"),
              ),
              TextButton(
                onPressed: () async {
                  await Client().downloadObject(
                    "filename.txt",
                    "./example/savePath.txt",
                    onReceiveProgress: (received, total) {
                      debugPrint("received = $received, total = $total");
                    },
                  );
                  _updateStatus("Download complete");
                },
                child: const Text("Download object"),
              ),
              TextButton(
                onPressed: () async {
                  final DeleteObjectResult result = await Client().deleteObject(
                    const DeleteObjectRequest(key: "filename.txt"),
                  );
                  _updateStatus(
                      "Deleted: ${result.deleted}, Status: ${result.statusCode}");
                },
                child: const Text("Delete object"),
              ),
              TextButton(
                onPressed: () async {
                  final results = await Future.wait([
                    Client().putObject(PutObjectRequest(
                      key: "filename1.txt",
                      data: Uint8List.fromList("files1".codeUnits),
                      onSendProgress: (count, total) {
                        if (kDebugMode) print("1: $count / $total");
                      },
                    )),
                    Client().putObject(PutObjectRequest(
                      key: "filename2.txt",
                      data: Uint8List.fromList("files2".codeUnits),
                      onSendProgress: (count, total) {
                        if (kDebugMode) print("2: $count / $total");
                      },
                    )),
                  ]);
                  _updateStatus("Batch upload: ${results.length} files, "
                      "statuses=[${results.map((r) => r.statusCode).join(', ')}]");
                },
                child: const Text("Batch upload"),
              ),
              TextButton(
                onPressed: () async {
                  final result = await Client().uploadFile(
                    const UploadFileRequest(
                      filepath: "/path/to/large-file.zip",
                      key: "uploads/large-file.zip",
                      multipartThreshold: 32 * 1024 * 1024,
                      partSize: 8 * 1024 * 1024,
                      parallel: 3,
                      resumable: true,
                      checkpointDir: "./example/.oss-checkpoints",
                    ),
                  );
                  _updateStatus(
                      "Auto upload: mode=${result.mode}, key=${result.key}");
                },
                child: const Text("Auto upload file"),
              ),
              TextButton(
                onPressed: () async {
                  final result = await Client().multipartUploadFile(
                    const MultipartUploadFileRequest(
                      filepath: "/path/to/archive.tar",
                      key: "uploads/archive.tar",
                      partSize: 8 * 1024 * 1024,
                      parallel: 3,
                      resumable: true,
                      checkpointDir: "./example/.oss-checkpoints",
                    ),
                  );
                  _updateStatus(
                    "Multipart upload: key=${result.key}, eTag=${result.eTag}",
                  );
                },
                child: const Text("Multipart upload"),
              ),
              TextButton(
                onPressed: () async {
                  final results = await Client().uploadFiles(
                    const UploadFilesRequest(
                      parallel: 2,
                      files: [
                        UploadFileRequest(
                          filepath: "/path/to/a.zip",
                          key: "uploads/a.zip",
                          resumable: true,
                          checkpointDir: "./example/.oss-checkpoints",
                        ),
                        UploadFileRequest(
                          filepath: "/path/to/b.zip",
                          key: "uploads/b.zip",
                          resumable: true,
                          checkpointDir: "./example/.oss-checkpoints",
                        ),
                      ],
                    ),
                  );
                  _updateStatus("Auto batch upload: ${results.length} files");
                },
                child: const Text("Auto batch upload"),
              ),
              TextButton(
                onPressed: () async {
                  final List<DeleteObjectResult> results =
                      await Client().deleteObjects(
                    const DeleteObjectsRequest(
                        keys: ["filename1.txt", "filename2.txt"]),
                  );
                  _updateStatus("Batch delete: ${results.length} files, "
                      "allDeleted=${results.every((r) => r.deleted)}");
                },
                child: const Text("Batch delete"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
