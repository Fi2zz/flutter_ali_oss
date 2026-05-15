# flutter_alioss

一个**强类型**、**零 dio 依赖**的阿里云对象存储服务（OSS）Flutter SDK。

---

## 关于阿里云 OSS

**阿里云对象存储服务（Object Storage Service，简称 OSS）** 是阿里云提供的海量、安全、低成本、高可靠的云存储服务。其数据设计持久性不低于 99.9999999999%（12 个 9），服务可用性（或业务连续性）不低于 99.995%。

- **官方文档首页**：https://www.aliyun.com/product/oss
- **开发者参考文档**：https://help.aliyun.com/zh/oss/developer-reference/overview
- **API 功能列表**：https://help.aliyun.com/zh/oss/developer-reference/list-of-operations-by-function
- **ListObjectsV2 API**：https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2
- **PutObject API**：https://help.aliyun.com/zh/oss/developer-reference/putobject
- **GetObject API**：https://help.aliyun.com/zh/oss/developer-reference/getobject

> 本 SDK 基于阿里云 OSS REST API 构建，所有操作均遵循阿里云官方 API 规范。
> 版权所有：阿里云（Alibaba Cloud）

---

## 为什么 fork

原包 `flutter_oss_aliyun` 存在两个核心问题：

1. **所有 API 返回 `dynamic`** — 你不得不猜测字段名和类型，编译器无法帮你发现拼写错误
2. **强耦合 dio** — 引入了大量不必要的依赖，且无法自定义 HTTP 层

本重写版解决了这两个问题：

- **强类型返回** — 每个 API 都有专属的 Result 类，IDE 自动补全 `result.eTag`、`object.size`、`bucket.creationDate`
- **零 dio 依赖** — 直接使用 `dart:io` HttpClient，零外部 HTTP 依赖
- **初始化极简** — 只需提供一个 `authenticator` 回调，无需 `stsUrl`、无需注入 `Dio`
- **类型安全的请求对象** — `ListObjectsRequest(maxKeys: 10, prefix: "images/")` 替代原始的 `Map<String, dynamic>`

---

## 快速开始

### 1. 添加依赖

```yaml
dependencies:
    flutter_alioss: ^1.0.0
```

### 2. 初始化客户端

```dart
import 'package:flutter_alioss/flutter_alioss.dart';

void main() {
  Client.init(
    ossEndpoint: 'oss-cn-hangzhou.aliyuncs.com',
    bucketName: 'my-bucket',
    authenticator: () async {
      // 从你的后端服务器获取 STS 临时凭证
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
}
```

`authenticator` 在凭证过期时会自动重新调用，无需手动管理 Token。

### 3. 使用强类型 API

```dart
final client = Client();

// 上传文件
final PutObjectResult result = await client.putObjectWithRequest(
  PutObjectRequest(
    key: 'avatars/user-42.jpg',
    data: imageBytes,
    aclMode: AclMode.private,
    storageType: StorageType.standard,
  ),
);
print('上传成功，ETag: ${result.eTag}');

// 列举对象（支持分页和过滤）
// 对应阿里云 API: ListObjectsV2
// 文档: https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2
final ListObjectsResult list = await client.listObjectsWithRequest(
  const ListObjectsRequest(maxKeys: 20, prefix: 'avatars/'),
);
for (final obj in list.objects) {
  print('${obj.key} — ${obj.size} bytes — ${obj.lastModified}');
}

// 获取对象的临时访问签名 URL
final String url = await client.getSignedUrl(
  'avatars/user-42.jpg',
  expireSeconds: 3600,
);

// 下载到本地
await client.downloadObject(
  'avatars/user-42.jpg',
  '/tmp/user-42.jpg',
  onReceiveProgress: (received, total) =>
    print('${(received / total * 100).toStringAsFixed(0)}%'),
);

// 删除
final DeleteObjectResult del = await client.deleteObject('avatars/user-42.jpg');
assert(del.deleted);
```

---

## 阿里云 OSS 数据类型映射

本 SDK 的强类型模型完整映射阿里云 OSS REST API 的 XML/HTTP 响应格式：

### 对象元数据

```dart
final ObjectMeta meta = await client.getObjectMeta('file.txt');
meta.contentLength;   // int      (HTTP Content-Length)
meta.contentType;     // String   (HTTP Content-Type)
meta.lastModified;    // DateTime (HTTP Last-Modified)
meta.eTag;            // String   (HTTP ETag)
meta.storageClass;    // String?  (x-oss-storage-class)
meta.serverSideEncryption; // String? (x-oss-server-side-encryption)
```

参考：[GetObjectMeta API 文档](https://help.aliyun.com/zh/oss/developer-reference/getobjectmeta)

### 列举对象结果

```dart
final ListObjectsResult result = await client.listObjectsWithRequest(
  const ListObjectsRequest(maxKeys: 10),
);

result.name;                    // String  Bucket 名称
result.prefix;                  // String  请求前缀
result.maxKeys;                 // int     最大返回条数
result.isTruncated;             // bool    是否截断
result.nextContinuationToken;   // String? 下一页 Token

for (final object in result.objects) {
  object.key;           // String   对象键名
  object.size;          // int      对象大小（字节）
  object.lastModified;  // DateTime 最后修改时间
  object.eTag;          // String   实体标签
  object.storageClass;  // String   存储类型（STANDARD / IA / ARCHIVE / COLDARCHIVE）
  object.type;          // String?  对象类型（Normal / Multipart / Appendable）
  object.owner?.id;     // String?  所有者 ID
}
```

参考：[ListObjectsV2 API 文档](https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2)

### 列举 Bucket 结果

```dart
final ListBucketsResult result = await client.listBucketsWithRequest(
  const ListBucketsRequest(maxKeys: 10),
);

result.owner.id;        // String  所有者 ID
result.owner.displayName; // String 所有者显示名

for (final bucket in result.buckets) {
  bucket.name;          // String  Bucket 名称
  bucket.creationDate;  // DateTime 创建时间
  bucket.location;      // String  地域（如 oss-cn-hangzhou）
  bucket.storageClass;  // String  存储类型
}
```

参考：[ListBuckets API 文档](https://help.aliyun.com/zh/oss/developer-reference/listbuckets)

### Bucket 信息

```dart
final BucketInfo info = await client.getBucketInfo();

info.name;              // String  Bucket 名称
info.location;          // String  地域
info.creationDate;      // DateTime 创建时间
info.extranetEndpoint;  // String  外网 Endpoint
info.intranetEndpoint;  // String  内网 Endpoint
info.acl;               // String  访问控制（private / public-read / public-read-write）
info.storageClass;      // String  默认存储类型
info.versioning;        // String?  版本控制状态
info.transferAcceleration; // String? 传输加速状态
```

参考：[GetBucketInfo API 文档](https://help.aliyun.com/zh/oss/developer-reference/getbucketinfo)

---

## 阿里云 OSS 存储类型

参考：[存储类型概述](https://help.aliyun.com/zh/oss/user-guide/overview-of-storage-classes)

| 枚举值                        | 阿里云值            | 适用场景                   |
| ----------------------------- | ------------------- | -------------------------- |
| `StorageType.standard`        | `"STANDARD"`        | 频繁访问的图片、视频、文件 |
| `StorageType.ia`              | `"IA"`              | 月均访问 1-2 次的备份数据  |
| `StorageType.archive`         | `"ARCHIVE"`         | 长期归档、需解冻后访问     |
| `StorageType.coldArchive`     | `"COLDARCHIVE"`     | 超长期冷归档               |
| `StorageType.deepColdArchive` | `"DEEPCOLDARCHIVE"` | 极少访问的合规归档         |

---

## 阿里云 OSS ACL 权限

参考：[访问控制（ACL）](https://help.aliyun.com/zh/oss/user-guide/acls)

| 枚举值                    | 阿里云值              | 说明                     |
| ------------------------- | --------------------- | ------------------------ |
| `AclMode.private`         | `"private"`           | 只有所有者可以读写       |
| `AclMode.publicRead`      | `"public-read"`       | 所有人可读，仅所有者可写 |
| `AclMode.publicReadWrite` | `"public-read-write"` | 所有人可读写（不推荐）   |
| `AclMode.inherited`       | `"default"`           | 继承 Bucket ACL          |

---

## API 对照表

| SDK 方法                                                     | 阿里云 OSS API                             | 文档链接                                                                           |
| ------------------------------------------------------------ | ------------------------------------------ | ---------------------------------------------------------------------------------- |
| `putObject` / `putObjectWithRequest`                         | PutObject                                  | [文档](https://help.aliyun.com/zh/oss/developer-reference/putobject)               |
| `getObject` / `getObjectWithRequest`                         | GetObject                                  | [文档](https://help.aliyun.com/zh/oss/developer-reference/getobject)               |
| `getObjectMeta`                                              | GetObjectMeta                              | [文档](https://help.aliyun.com/zh/oss/developer-reference/getobjectmeta)           |
| `copyObject` / `copyObjectWithRequest`                       | CopyObject                                 | [文档](https://help.aliyun.com/zh/oss/developer-reference/copyobject)              |
| `appendObject` / `appendObjectWithRequest`                   | AppendObject                               | [文档](https://help.aliyun.com/zh/oss/developer-reference/appendobject)            |
| `deleteObject`                                               | DeleteObject                               | [文档](https://help.aliyun.com/zh/oss/developer-reference/deleteobject)            |
| `listObjects` / `listObjectsWithRequest`                     | ListObjectsV2                              | [文档](https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2)           |
| `listBuckets` / `listBucketsWithRequest`                     | ListBuckets                                | [文档](https://help.aliyun.com/zh/oss/developer-reference/listbuckets)             |
| `getBucketInfo`                                              | GetBucketInfo                              | [文档](https://help.aliyun.com/zh/oss/developer-reference/getbucketinfo)           |
| `getBucketStat`                                              | GetBucketStat                              | [文档](https://help.aliyun.com/zh/oss/developer-reference/getbucketstat)           |
| `getBucketAcl` / `putBucketAcl`                              | GetBucketAcl / PutBucketAcl                | [文档](https://help.aliyun.com/zh/oss/developer-reference/getbucketacl)            |
| `getBucketPolicy` / `putBucketPolicy` / `deleteBucketPolicy` | Bucket Policy                              | [文档](https://help.aliyun.com/zh/oss/user-guide/bucket-policy)                    |
| `getSignedUrl`                                               | 签名 URL                                   | [文档](https://help.aliyun.com/zh/oss/developer-reference/signatures)              |
| `downloadObject`                                             | GetObject（流式下载）                      | [文档](https://help.aliyun.com/zh/oss/developer-reference/getobject)               |
| `getAllRegions` / `getRegion`                                | GetRegion                                  | [文档](https://help.aliyun.com/zh/oss/developer-reference/regions-endpoints)       |
| `initiateMultipartUpload`                                    | InitiateMultipartUpload                    | [文档](https://help.aliyun.com/zh/oss/developer-reference/initiatemultipartupload) |
| `uploadPart`                                                 | UploadPart                                 | [文档](https://help.aliyun.com/zh/oss/developer-reference/uploadpart)              |
| `completeMultipartUpload`                                    | CompleteMultipartUpload                    | [文档](https://help.aliyun.com/zh/oss/developer-reference/completemultipartupload) |
| `abortMultipartUpload`                                       | AbortMultipartUpload                       | [文档](https://help.aliyun.com/zh/oss/developer-reference/abortmultipartupload)    |
| `listMultipartUploads`                                       | ListMultipartUploads                       | [文档](https://help.aliyun.com/zh/oss/developer-reference/listmultipartuploads)    |
| `listParts`                                                  | ListParts                                  | [文档](https://help.aliyun.com/zh/oss/developer-reference/listparts)               |
| `multipartUploadFile` / `multipartUploadFiles`               | Multipart Upload（SDK 高层封装）           | [文档](https://help.aliyun.com/zh/oss/user-guide/multipart-upload)                 |
| `uploadFile` / `uploadFiles`                                 | 自动选择普通上传或分片上传（SDK 高层封装） | [文档](https://help.aliyun.com/zh/oss/user-guide/multipart-upload)                 |

---

## 请求类型（Request Classes）

| 操作     | 旧版（仍兼容）                            | 新版（推荐）                                                        |
| -------- | ----------------------------------------- | ------------------------------------------------------------------- |
| 列举对象 | `listObjects({"max-keys": 10})`           | `listObjectsWithRequest(ListObjectsRequest(maxKeys: 10))`           |
| 上传对象 | `putObject(bytes, "key", option: ...)`    | `putObjectWithRequest(PutObjectRequest(key: "key", data: bytes))`   |
| 拷贝对象 | `copyObject(CopyRequestOption(...))`      | `copyObjectWithRequest(CopyObjectRequest(...))`                     |
| 追加上传 | `appendObject(bytes, "key", position: n)` | `appendObjectWithRequest(AppendObjectRequest(...))`                 |
| 上传文件 | `putObjectFile("/path", option: ...)`     | `putObjectFileWithRequest(PutObjectFileRequest(filepath: "/path"))` |

---

## 分片上传 Multipart Upload

当文件较大时，推荐使用 Multipart Upload。SDK 同时提供底层 API 和高层封装。

### 高层封装：单文件分片上传

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
      print('总进度: $count / $total');
    },
    onPartProgress: (partNumber, count, total) {
      print('分片 $partNumber: $count / $total');
    },
  ),
);

print(result.bucket);
print(result.key);
print(result.eTag);
```

### 高层封装：批量分片上传

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
      print('批量分片上传: $completed / $total');
    },
  ),
);

print(results.map((item) => item.key).toList());
```

### 底层 API：手动控制分片流程

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

### 查询与取消分片任务

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

### 断点续传说明

- 开启 `resumable: true` 后，SDK 会把 `uploadId` 和已完成分片写入 `checkpointDir`
- 同一个文件再次发起上传时，会优先读取 checkpoint，仅补传缺失分片
- 如果本地文件大小或最后修改时间发生变化，旧 checkpoint 会自动失效并删除
- 未开启 `resumable` 时，分片上传失败会自动调用 `abortMultipartUpload`

---

## 自动上传与断点续传

小文件可以直接走普通上传，大文件可以自动切换到 Multipart Upload：

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
      print('总进度: $count / $total');
    },
    onPartProgress: (partNumber, count, total) {
      print('分片 $partNumber: $count / $total');
    },
  ),
);

print(result.mode);      // UploadMode.simple / UploadMode.multipart
print(result.location);  // 对象访问地址
```

如果中途失败，再次调用同样的 `UploadFileRequest` 会优先读取 checkpoint，仅续传未完成分片。

### 批量自动上传

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
      print('批量进度: $completed / $total');
    },
  ),
);

print(results.map((item) => item.mode).toList());
```

### 分片任务查询

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

## 取消操作

所有异步方法都支持可选的 `CancelToken`：

```dart
final token = CancelToken();

client.putObjectWithRequest(
  PutObjectRequest(key: 'big.zip', data: bytes),
  cancelToken: token,
);

// 稍后取消
token.cancel('用户取消');  // 在等待处抛出 CancelException
```

---

## 错误处理

SDK 在 HTTP 错误时抛出 `OssException`：

```dart
try {
  await client.getObjectMeta('不存在的文件.txt');
} on OssException catch (e) {
  print('${e.statusCode}: ${e.message}');     // 404: NoSuchKey
  print('Request ID: ${e.requestId}');         // 用于阿里云技术支持排查
  print('错误码: ${e.code}');                   // NoSuchKey
}
```

常见阿里云 OSS 错误码：[错误响应](https://help.aliyun.com/zh/oss/developer-reference/error-responses)

---

## 与原版 `flutter_oss_aliyun` 的破坏性变更

| 变更项       | 之前                                         | 之后                                                 |
| ------------ | -------------------------------------------- | ---------------------------------------------------- |
| 初始化       | `Client.init(stsUrl: ..., authGetter: ...)`  | `Client.init(authenticator: ...)`（必填）            |
| dio 注入     | `Client.init(dio: myDio)`                    | 已移除 — 不再使用 dio                                |
| 列举对象返回 | `Future<Response<dynamic>> listObjects(...)` | `Future<ListObjectsResult> listObjects(...)`         |
| 上传对象返回 | `Future<Response<dynamic>> putObject(...)`   | `Future<PutObjectResult> putObject(...)`             |
| CancelToken  | `package:dio` 的 CancelToken                 | `package:flutter_alioss` 的 CancelToken              |
| 响应类型     | `Response<dynamic>` (dio)                    | `BytesResponse` / `StringResponse` / `EmptyResponse` |

---

## 许可

本 SDK 基于阿里云 OSS REST API 构建。阿里云及阿里云 OSS 相关的商标、文档版权归[阿里巴巴集团](https://www.alibabagroup.com/)所有。

本项目采用 MIT 许可证。参见 [LICENSE](LICENSE) 文件。
