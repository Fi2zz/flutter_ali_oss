Language: [中文简体](README.md) | [English](README_EN.md)

# flutter_alioss

A **strongly-typed**, **dio-free** Flutter SDK for Alibaba Cloud Object Storage Service (OSS).

## About Alibaba Cloud OSS

**Alibaba Cloud Object Storage Service (OSS)** is a massive, secure, low-cost, and highly reliable cloud storage service provided by Alibaba Cloud. Its data design durability is no less than 99.9999999999% (12 nines), and service availability (or business continuity) is no less than 99.995%.

- **Official Website**: https://www.aliyun.com/product/oss
- **Developer Reference**: https://help.aliyun.com/zh/oss/developer-reference/overview
- **API Operations by Function**: https://help.aliyun.com/zh/oss/developer-reference/list-of-operations-by-function
- **ListObjectsV2 API**: https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2
- **PutObject API**: https://help.aliyun.com/zh/oss/developer-reference/putobject
- **GetObject API**: https://help.aliyun.com/zh/oss/developer-reference/getobject

> This SDK is built on top of the Alibaba Cloud OSS REST API. All operations follow the official Alibaba Cloud API specifications.
> Copyright: Alibaba Cloud

---

## Why fork?

The original package `flutter_oss_aliyun` had two core problems:

1. **All APIs returned `dynamic`** — you had to guess field names and types, and the compiler couldn't catch typos
2. **Strongly coupled to dio** — introduced unnecessary dependencies and prevented custom HTTP layers

This rewrite solves both:

- **Strongly-typed results** — every API has a dedicated Result class with full IDE autocomplete
- **Zero dio dependency** — uses `dart:io` HttpClient directly, zero external HTTP dependencies
- **Simplified init** — just provide an `authenticator` callback; no `stsUrl`, no `Dio` injection
- **Type-safe request objects** — `ListObjectsRequest(maxKeys: 10, prefix: "images/")` instead of raw `Map<String, dynamic>`

---

## Quick Start

### 1. Add dependency

```yaml
dependencies:
    flutter_alioss: ^1.0.0
```

### 2. Initialize the client

```dart
import 'package:flutter_alioss/flutter_alioss.dart';

Client.init(
  ossEndpoint: 'oss-cn-hangzhou.aliyuncs.com',
  bucketName: 'my-bucket',
  authenticator: () async {
    // Fetch STS credentials from your backend server
    final response = await http.get(Uri.parse('https://your-server.com/sts'));
    final json = jsonDecode(response.body);
    return Auth(
      accessKey:    json['AccessKeyId'],
      accessSecret: json['AccessKeySecret'],
      secureToken:  json['SecurityToken'],
      expire:       json['Expiration'],
    );
  },
);
```

`authenticator` is called automatically whenever credentials expire.

### 3. Use the typed API

```dart
final client = Client();

// Upload
final PutObjectResult result = await client.putObjectWithRequest(
  PutObjectRequest(
    key: 'avatars/user-42.jpg',
    data: imageBytes,
    aclMode: AclMode.private,
    storageType: StorageType.standard,
  ),
);
print('Uploaded, ETag: ${result.eTag}');

// List objects
final ListObjectsResult list = await client.listObjectsWithRequest(
  const ListObjectsRequest(maxKeys: 20, prefix: 'avatars/'),
);
for (final obj in list.objects) {
  print('${obj.key} - ${obj.size} bytes - ${obj.lastModified}');
}

// Get signed URL (valid for 1 hour)
final String url = await client.getSignedUrl(
  'avatars/user-42.jpg',
  expireSeconds: 3600,
);

// Download
await client.downloadObject(
  'avatars/user-42.jpg',
  '/tmp/user-42.jpg',
  onReceiveProgress: (received, total) =>
    print('${(received / total * 100).toStringAsFixed(0)}%'),
);

// Delete
final DeleteObjectResult del = await client.deleteObject('avatars/user-42.jpg');
assert(del.deleted);
```

---

## Typed Request Classes

| Operation     | Legacy (still works)                      | Typed (recommended)                                                 |
| ------------- | ----------------------------------------- | ------------------------------------------------------------------- |
| List objects  | `listObjects({"max-keys": 10})`           | `listObjectsWithRequest(ListObjectsRequest(maxKeys: 10))`           |
| Put object    | `putObject(bytes, "key", option: ...)`    | `putObjectWithRequest(PutObjectRequest(key: "key", data: bytes))`   |
| Copy object   | `copyObject(CopyRequestOption(...))`      | `copyObjectWithRequest(CopyObjectRequest(...))`                     |
| Append object | `appendObject(bytes, "key", position: n)` | `appendObjectWithRequest(AppendObjectRequest(...))`                 |
| Put file      | `putObjectFile("/path", option: ...)`     | `putObjectFileWithRequest(PutObjectFileRequest(filepath: "/path"))` |

---

## Multipart Upload

For large files, Multipart Upload is recommended. The SDK provides both low-level APIs and high-level helpers.

### High-Level Helper: Single File Multipart Upload

```dart
final result = await Client().multipartUploadFile(
  MultipartUploadFileRequest(
    filepath: '/local/path/archive.tar',
    key: 'backup/archive.tar',
    partSize: 8 * 1024 * 1024,
    parallel: 3,
    resumable: true,
    checkpointDir: '/local/path/.oss-checkpoints',
    onSendProgress: (count, total) {
      print('overall: $count / $total');
    },
    onPartProgress: (partNumber, count, total) {
      print('part $partNumber: $count / $total');
    },
  ),
);

print(result.bucket);
print(result.key);
print(result.eTag);
```

### High-Level Helper: Batch Multipart Upload

```dart
final results = await Client().multipartUploadFiles(
  MultipartUploadFilesRequest(
    parallel: 2,
    files: const [
      MultipartUploadFileRequest(
        filepath: '/local/path/a.tar',
        key: 'backup/a.tar',
        resumable: true,
        checkpointDir: '/local/path/.oss-checkpoints',
      ),
      MultipartUploadFileRequest(
        filepath: '/local/path/b.tar',
        key: 'backup/b.tar',
        resumable: true,
        checkpointDir: '/local/path/.oss-checkpoints',
      ),
    ],
    onProgress: (completed, total) {
      print('batch multipart: $completed / $total');
    },
  ),
);

print(results.map((item) => item.key).toList());
```

### Low-Level API: Manual Multipart Flow

```dart
final init = await Client().initiateMultipartUpload(
  const InitiateMultipartUploadRequest(
    key: 'backup/manual.tar',
  ),
);

final part1 = await Client().uploadPart(
  UploadPartRequest(
    key: 'backup/manual.tar',
    uploadId: init.uploadId,
    partNumber: 1,
    data: bytesPart1,
  ),
);

final part2 = await Client().uploadPart(
  UploadPartRequest(
    key: 'backup/manual.tar',
    uploadId: init.uploadId,
    partNumber: 2,
    data: bytesPart2,
  ),
);

final complete = await Client().completeMultipartUpload(
  CompleteMultipartUploadRequest(
    key: 'backup/manual.tar',
    uploadId: init.uploadId,
    parts: [
      UploadedPart(partNumber: 1, eTag: part1.eTag),
      UploadedPart(partNumber: 2, eTag: part2.eTag),
    ],
  ),
);

print(complete.location);
```

### Inspect And Abort Multipart Tasks

```dart
final uploads = await Client().listMultipartUploads(
  const ListMultipartUploadsRequest(prefix: 'backup/'),
);

final first = uploads.uploads.first;

final parts = await Client().listParts(
  ListPartsRequest(
    key: first.key,
    uploadId: first.uploadId,
  ),
);

print(parts.parts.length);

await Client().abortMultipartUpload(first.key, first.uploadId);
```

### Resume Notes

- With `resumable: true`, the SDK stores `uploadId` and completed parts in `checkpointDir`
- Re-running the same upload resumes missing parts only
- If file size or modification time changes, the old checkpoint is dropped automatically
- Without `resumable`, failed multipart uploads are aborted automatically

---

## Auto Upload And Resume

Small files can use simple upload, while large files can switch to Multipart Upload automatically:

```dart
final result = await Client().uploadFile(
  UploadFileRequest(
    filepath: '/local/path/video.mp4',
    key: 'videos/video.mp4',
    multipartThreshold: 32 * 1024 * 1024,
    partSize: 8 * 1024 * 1024,
    parallel: 3,
    resumable: true,
    checkpointDir: '/local/path/.oss-checkpoints',
    onSendProgress: (count, total) {
      print('overall: $count / $total');
    },
    onPartProgress: (partNumber, count, total) {
      print('part $partNumber: $count / $total');
    },
  ),
);

print(result.mode);
print(result.location);
```

If the upload fails midway, calling the same `UploadFileRequest` again reuses the checkpoint file and only uploads missing parts.

### Batch Auto Upload

```dart
final results = await Client().uploadFiles(
  UploadFilesRequest(
    parallel: 2,
    files: const [
      UploadFileRequest(
        filepath: '/local/path/a.zip',
        key: 'backup/a.zip',
        resumable: true,
        checkpointDir: '/local/path/.oss-checkpoints',
      ),
      UploadFileRequest(
        filepath: '/local/path/b.zip',
        key: 'backup/b.zip',
        resumable: true,
        checkpointDir: '/local/path/.oss-checkpoints',
      ),
    ],
    onProgress: (completed, total) {
      print('batch: $completed / $total');
    },
  ),
);

print(results.map((item) => item.mode).toList());
```

### Inspect Multipart Tasks

```dart
final uploads = await Client().listMultipartUploads(
  const ListMultipartUploadsRequest(prefix: 'backup/'),
);

final parts = await Client().listParts(
  ListPartsRequest(
    key: uploads.uploads.first.key,
    uploadId: uploads.uploads.first.uploadId,
  ),
);

print(parts.parts.length);
```

---

## Typed Result Classes

| API Method                                 | Return Type          | Key Fields                                                         |
| ------------------------------------------ | -------------------- | ------------------------------------------------------------------ |
| `putObject` / `putObjectWithRequest`       | `PutObjectResult`    | `eTag`, `statusCode`, `versionId`                                  |
| `copyObject` / `copyObjectWithRequest`     | `CopyObjectResult`   | `eTag`, `lastModified`                                             |
| `appendObject` / `appendObjectWithRequest` | `AppendObjectResult` | `nextPosition`, `eTag`                                             |
| `deleteObject`                             | `DeleteObjectResult` | `deleted`, `statusCode`, `key`                                     |
| `getObjectMeta`                            | `ObjectMeta`         | `contentLength`, `contentType`, `lastModified`, `eTag`             |
| `listObjects` / `listObjectsWithRequest`   | `ListObjectsResult`  | `objects: List<OSSObject>`, `isTruncated`, `nextContinuationToken` |
| `listBuckets` / `listBucketsWithRequest`   | `ListBucketsResult`  | `buckets: List<Bucket>`, `owner`                                   |
| `getBucketInfo`                            | `BucketInfo`         | `name`, `location`, `creationDate`, `acl`, `storageClass`          |
| `getBucketStat`                            | `BucketStat`         | `storage`, `objectCount`, `standardStorage`, `archiveStorage`      |
| `getBucketAcl`                             | `BucketAcl`          | `grant` (e.g. `"private"`, `"public-read"`)                        |
| `getAllRegions` / `getRegion`              | `RegionsResult`      | `regions: List<Region>`                                            |

---

## Object Model

When listing objects, each item is a fully-typed `OSSObject`:

```dart
for (final object in result.objects) {
  object.key;           // String
  object.size;          // int (bytes)
  object.lastModified;  // DateTime
  object.eTag;          // String
  object.storageClass;  // String ("STANDARD", "IA", "ARCHIVE", ...)
  object.type;          // String? ("Normal", "Multipart", "Appendable")
  object.owner?.id;     // String?
}
```

---

## OSS Storage Classes

Reference: [Storage Class Overview](https://help.aliyun.com/zh/oss/user-guide/overview-of-storage-classes)

| Enum Value                | OSS Value       | Use Case                                  |
| ------------------------- | --------------- | ----------------------------------------- |
| `StorageType.standard`    | `"STANDARD"`    | Frequently accessed images, videos, files |
| `StorageType.ia`          | `"IA"`          | Backups accessed 1-2 times per month      |
| `StorageType.archive`     | `"ARCHIVE"`     | Long-term archive, requires thawing       |
| `StorageType.coldArchive` | `"COLDARCHIVE"` | Ultra-long-term cold archive              |

---

## OSS ACL Permissions

Reference: [Access Control (ACL)](https://help.aliyun.com/zh/oss/user-guide/acls)

| Enum Value                | OSS Value             | Description                             |
| ------------------------- | --------------------- | --------------------------------------- |
| `AclMode.private`         | `"private"`           | Only owner can read/write               |
| `AclMode.publicRead`      | `"public-read"`       | Anyone can read, only owner can write   |
| `AclMode.publicReadWrite` | `"public-read-write"` | Anyone can read/write (not recommended) |
| `AclMode.inherited`       | `"default"`           | Inherit Bucket ACL                      |

---

## API Reference Table

| SDK Method                                                   | Alibaba Cloud OSS API                                          | Documentation                                                                      |
| ------------------------------------------------------------ | -------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `putObject` / `putObjectWithRequest`                         | PutObject                                                      | [Docs](https://help.aliyun.com/zh/oss/developer-reference/putobject)               |
| `getObject` / `getObjectWithRequest`                         | GetObject                                                      | [Docs](https://help.aliyun.com/zh/oss/developer-reference/getobject)               |
| `getObjectMeta`                                              | GetObjectMeta                                                  | [Docs](https://help.aliyun.com/zh/oss/developer-reference/getobjectmeta)           |
| `copyObject` / `copyObjectWithRequest`                       | CopyObject                                                     | [Docs](https://help.aliyun.com/zh/oss/developer-reference/copyobject)              |
| `appendObject` / `appendObjectWithRequest`                   | AppendObject                                                   | [Docs](https://help.aliyun.com/zh/oss/developer-reference/appendobject)            |
| `deleteObject`                                               | DeleteObject                                                   | [Docs](https://help.aliyun.com/zh/oss/developer-reference/deleteobject)            |
| `listObjects` / `listObjectsWithRequest`                     | ListObjectsV2                                                  | [Docs](https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2)           |
| `listBuckets` / `listBucketsWithRequest`                     | ListBuckets                                                    | [Docs](https://help.aliyun.com/zh/oss/developer-reference/listbuckets)             |
| `getBucketInfo`                                              | GetBucketInfo                                                  | [Docs](https://help.aliyun.com/zh/oss/developer-reference/getbucketinfo)           |
| `getBucketStat`                                              | GetBucketStat                                                  | [Docs](https://help.aliyun.com/zh/oss/developer-reference/getbucketstat)           |
| `getBucketAcl` / `putBucketAcl`                              | GetBucketAcl / PutBucketAcl                                    | [Docs](https://help.aliyun.com/zh/oss/developer-reference/getbucketacl)            |
| `getBucketPolicy` / `putBucketPolicy` / `deleteBucketPolicy` | Bucket Policy                                                  | [Docs](https://help.aliyun.com/zh/oss/user-guide/bucket-policy)                    |
| `getSignedUrl`                                               | Signed URL                                                     | [Docs](https://help.aliyun.com/zh/oss/developer-reference/signatures)              |
| `downloadObject`                                             | GetObject (stream download)                                    | [Docs](https://help.aliyun.com/zh/oss/developer-reference/getobject)               |
| `getAllRegions` / `getRegion`                                | GetRegion                                                      | [Docs](https://help.aliyun.com/zh/oss/developer-reference/regions-endpoints)       |
| `initiateMultipartUpload`                                    | InitiateMultipartUpload                                        | [Docs](https://help.aliyun.com/zh/oss/developer-reference/initiatemultipartupload) |
| `uploadPart`                                                 | UploadPart                                                     | [Docs](https://help.aliyun.com/zh/oss/developer-reference/uploadpart)              |
| `completeMultipartUpload`                                    | CompleteMultipartUpload                                        | [Docs](https://help.aliyun.com/zh/oss/developer-reference/completemultipartupload) |
| `abortMultipartUpload`                                       | AbortMultipartUpload                                           | [Docs](https://help.aliyun.com/zh/oss/developer-reference/abortmultipartupload)    |
| `listMultipartUploads`                                       | ListMultipartUploads                                           | [Docs](https://help.aliyun.com/zh/oss/developer-reference/listmultipartuploads)    |
| `listParts`                                                  | ListParts                                                      | [Docs](https://help.aliyun.com/zh/oss/developer-reference/listparts)               |
| `multipartUploadFile` / `multipartUploadFiles`               | Multipart Upload (high-level SDK helper)                       | [Docs](https://help.aliyun.com/zh/oss/user-guide/multipart-upload)                 |
| `uploadFile` / `uploadFiles`                                 | Auto-select simple or multipart upload (high-level SDK helper) | [Docs](https://help.aliyun.com/zh/oss/user-guide/multipart-upload)                 |

---

## Cancellation

All async operations accept an optional `CancelToken`:

```dart
final token = CancelToken();

client.putObjectWithRequest(
  PutObjectRequest(key: 'big.zip', data: bytes),
  cancelToken: token,
);

// Cancel later
token.cancel('User cancelled');  // throws CancelException
```

---

## Error Handling

The SDK throws `OssException` on HTTP errors:

```dart
try {
  await client.getObjectMeta('nonexistent.txt');
} on OssException catch (e) {
  print('${e.statusCode}: ${e.message}');     // 404: NoSuchKey
  print('Request ID: ${e.requestId}');         // For Alibaba Cloud tech support
  print('Code: ${e.code}');                    // NoSuchKey
}
```

Common OSS error codes: [Error Responses](https://help.aliyun.com/zh/oss/developer-reference/error-responses)

---

## Breaking Changes from `flutter_oss_aliyun`

| Before                                       | After                                              |
| -------------------------------------------- | -------------------------------------------------- |
| `Client.init(stsUrl: ..., authGetter: ...)`  | `Client.init(authenticator: ...)` (required)       |
| `Client.init(dio: myDio)`                    | Removed — dio no longer used                       |
| `Future<Response<dynamic>> listObjects(...)` | `Future<ListObjectsResult> listObjects(...)`       |
| `Future<Response<dynamic>> putObject(...)`   | `Future<PutObjectResult> putObject(...)`           |
| `CancelToken` from `package:dio`             | `CancelToken` from `package:flutter_alioss`        |
| `Response<dynamic>` from dio                 | `BytesResponse`, `StringResponse`, `EmptyResponse` |

---

## License

This SDK is built on the Alibaba Cloud OSS REST API. Alibaba Cloud and Alibaba Cloud OSS trademarks and documentation are copyrighted by [Alibaba Group](https://www.alibabagroup.com/).

This project is licensed under the MIT License. See [LICENSE](LICENSE) file.
