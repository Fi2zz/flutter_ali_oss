import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_alioss/flutter_alioss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String home;
  late String callbackUrl;

  setUpAll(() {
    final Map<String, String> env = Platform.environment;
    home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;
    callbackUrl = env['oss_callback_url'] ?? "";

    Client.init(
      ossEndpoint: env["oss_endpoint"] ?? "",
      bucketName: env["bucket_name"] ?? "",
      authenticator: () async {
        return Auth(
          accessKey: env["oss_access_key"] ?? "",
          accessSecret: env["oss_access_secret"] ?? "",
          secureToken: env["oss_security_token"] ?? "",
          expire: env["oss_expire"] ?? "2099-01-01T00:00:00Z",
        );
      },
    );
  });

  test("put object", () async {
    final File file = File("$home/Downloads/idiom.csv");
    final String string = await file.readAsString();

    final PutObjectResult result = await Client().putObject(
      PutObjectRequest(
        key: "test.csv",
        data: Uint8List.fromList(utf8.encode(string)),
        aclMode: AclMode.publicRead,
        storageType: StorageType.ia,
        headers: {"content-type": "text/csv"},
        callback: Callback(
          callbackUrl: callbackUrl,
          callbackBody:
              r'{"mimeType":${mimeType},"filepath":${object},"size":${size},"bucket":${bucket},"phone":${x:phone}}',
          callbackVar: {"x:phone": "android"},
          calbackBodyType: CallbackBodyType.json,
        ),
        onSendProgress: (count, total) {
          print("send: count = $count, and total = $total");
        },
      ),
    );

    expect(result.statusCode, 200);
    expect(result.eTag, isNotEmpty);
  });

  test("copy object", () async {
    final CopyObjectResult result = await Client().copyObject(
      const CopyObjectRequest(
        sourceKey: 'test.csv',
        targetKey: "test_copy.csv",
      ),
    );

    expect(result.eTag, isNotEmpty);
  });

  test("append object", () async {
    final AppendObjectResult result1 = await Client().appendObject(
      AppendObjectRequest(
        key: "test_append.txt",
        data: Uint8List.fromList(utf8.encode("Hello World")),
      ),
    );

    expect(result1.statusCode, 200);
    expect(result1.nextPosition, 11);

    final AppendObjectResult result2 = await Client().appendObject(
      AppendObjectRequest(
        key: "test_append.txt",
        data: Uint8List.fromList(utf8.encode(", Fluter.")),
        position: 11,
      ),
    );

    expect(result2.statusCode, 200);
    expect(result2.nextPosition, 20);

    await Client().deleteObject(const DeleteObjectRequest(key: "test_append.txt"));
  });

  test("get object metadata", () async {
    final ObjectMeta meta = await Client().getObjectMeta("test.csv");

    expect(meta.contentLength, greaterThan(0));
    expect(meta.eTag, isNotEmpty);
    expect(meta.lastModified, isNotNull);
  });

  test("get all regions", () async {
    final RegionsResult result = await Client().getAllRegions();

    expect(result.regions, isNotEmpty);
  });

  test("get region", () async {
    final RegionsResult result = await Client().getRegion("oss-ap-northeast-1");

    expect(result.regions, isNotEmpty);
  });

  test("put bucket acl", () async {
    await Client().putBucketAcl(AclMode.publicRead, bucketName: "huhx-family-dev");
  });

  test("get bucket acl", () async {
    final BucketAcl acl = await Client().getBucketAcl(bucketName: "huhx-family-dev");

    expect(acl.grant, isNotEmpty);
  });

  test("get bucket policy", () async {
    final String? policy = await Client().getBucketPolicy(bucketName: "huhx-family-dev");
    print("bucket policy: $policy");
  });

  test("delete bucket policy", () async {
    await Client().deleteBucketPolicy(bucketName: "huhx-family-dev");
  });

  test("put bucket policy", () async {
    const Map<String, dynamic> policy = {
      "Version": "1",
      "Statement": [
        {
          "Principal": ["221050028580141672"],
          "Effect": "Allow",
          "Resource": [
            "acs:oss:*:1504416580632704:huhx-family-dev",
            "acs:oss:*:1504416580632704:huhx-family-dev/*"
          ],
          "Action": [
            "oss:GetObject",
            "oss:GetObjectAcl",
            "oss:RestoreObject",
            "oss:GetVodPlaylist",
            "oss:GetObjectVersion",
            "oss:GetObjectVersionAcl",
            "oss:RestoreObjectVersion"
          ]
        }
      ]
    };

    await Client().putBucketPolicy(policy, bucketName: "huhx-family-dev");
  });

  test("put object file", () async {
    final PutObjectResult result = await Client().putObjectFile(
      PutObjectFileRequest(
        filepath: "$home/Downloads/journal_bg-min.png",
        key: "aaa.png",
        aclMode: AclMode.private,
        callback: Callback(
          callbackUrl: callbackUrl,
          callbackBody:
              r'{"mimeType":${mimeType},"filepath":${object},"size":${size},"bucket":${bucket},"phone":${x:phone}}',
          callbackVar: {"x:phone": "android"},
          calbackBodyType: CallbackBodyType.json,
        ),
        onSendProgress: (count, total) {
          print("send: count = $count, and total = $total");
        },
      ),
    );

    expect(result.statusCode, 200);
    expect(result.eTag, isNotEmpty);
  });

  test("list objects", () async {
    final ListObjectsResult result = await Client().listObjects(
      const ListObjectsRequest(maxKeys: 12, prefix: "aaa"),
    );

    print("Bucket: ${result.name}, Objects count: ${result.objects.length}");
    expect(result.name, isNotEmpty);
  });

  test("list buckets", () async {
    final ListBucketsResult result = await Client().listBuckets(
      const ListBucketsRequest(maxKeys: 2),
    );

    print("Buckets: ${result.buckets.length}");
    expect(result.buckets, isNotEmpty);
  });

  test("get bucket info", () async {
    final BucketInfo info = await Client().getBucketInfo();

    print("Bucket: ${info.name}, Location: ${info.location}");
    expect(info.name, isNotEmpty);
    expect(info.location, isNotEmpty);
  });

  test("get bucket stat", () async {
    final BucketStat stat = await Client().getBucketStat();

    print("Storage: ${stat.storage}, Objects: ${stat.objectCount}");
    expect(stat.storage, greaterThanOrEqualTo(0));
    expect(stat.objectCount, greaterThanOrEqualTo(0));
  });

  test("get object", () async {
    final BytesResponse resp = await Client().getObject(
      const GetObjectRequest(key: "test.txt"),
    );

    expect(resp.statusCode, 200);
    expect(resp.data, isNotEmpty);
  });

  test("download object", () async {
    final EmptyResponse resp = await Client().downloadObject(
      "test.txt",
      "result.txt",
    );
    final File file = File("result.txt");

    expect(resp.statusCode, 200);
    expect(file.existsSync(), true);

    file.delete();
  });

  test("delete object", () async {
    final DeleteObjectResult result = await Client().deleteObject(
      const DeleteObjectRequest(key: "test.txt"),
    );

    expect(result.deleted, true);
    expect(result.statusCode, 204);
  });

  test("put objects", () async {
    final List<PutObjectResult> results = await Future.wait([
      Client().putObject(PutObjectRequest(
        key: "filename1.txt",
        data: Uint8List.fromList(utf8.encode("files1")),
      )),
      Client().putObject(PutObjectRequest(
        key: "filename2.txt",
        data: Uint8List.fromList(utf8.encode("files2")),
      )),
    ]);

    expect(results.length, 2);
    expect(results[0].statusCode, 200);
    expect(results[1].statusCode, 200);
  });

  test("delete objects", () async {
    final List<DeleteObjectResult> results = await Client().deleteObjects(
      const DeleteObjectsRequest(keys: ["filename1.txt", "filename2.txt"]),
    );

    expect(results.length, 2);
    expect(results[0].deleted, true);
    expect(results[1].deleted, true);
  });

  test("get signed url", () async {
    final String url = await Client().getSignedUrl(
      "20220106121416393842.jpg",
      params: {"x-oss-process": "image/resize,w_10/quality,q_90", "aaa": "bb"},
    );
    print("download url = $url");

    expect(url, isNotNull);
  });

  test("get signed urls", () async {
    final Map<String, String> result = await Client().getSignedUrls([
      "20220106121416393842.jpg",
      "20220106095156755058.jpg",
    ]);

    print(result);

    expect(result.length, 2);
  });

  test("doesObjectExist", () async {
    final bool isExisted = await Client().doesObjectExist(
      "20220106121416393842.jpg",
    );

    expect(isExisted, true);
  });
}
