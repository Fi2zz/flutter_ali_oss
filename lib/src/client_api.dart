// 阿里云对象存储服务（OSS）Client API 接口定义
// 对应阿里云 OSS REST API 规范
// 文档: https://help.aliyun.com/zh/oss/developer-reference/list-of-operations-by-function

import 'dart:async';

import 'model/enums.dart';
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
import 'util/oss_response.dart';

/// 传输进度回调：已传输/接收字节数，总字节数
typedef ProgressCallback = void Function(int count, int total);

/// 阿里云 OSS 客户端接口
///
/// 所有方法均使用强类型参数和强类型返回结果
abstract class ClientApi {
  // ==================== 对象操作 ====================

  /// 上传对象
  /// 对应阿里云 API: PutObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/putobject
  Future<PutObjectResult> putObject(PutObjectRequest request,
      {CancelToken? cancelToken});

  /// 上传文件
  /// 对应阿里云 API: PutObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/putobject
  Future<PutObjectResult> putObjectFile(PutObjectFileRequest request,
      {CancelToken? cancelToken});

  /// 批量上传文件
  /// 对应阿里云 API: PutObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/putobject
  Future<List<PutObjectResult>> putObjectFiles(
    PutObjectFilesRequest request, {
    CancelToken? cancelToken,
  });

  /// 自动选择普通上传或分片上传
  Future<UploadFileResult> uploadFile(
    UploadFileRequest request, {
    CancelToken? cancelToken,
  });

  /// 批量自动上传文件
  Future<List<UploadFileResult>> uploadFiles(
    UploadFilesRequest request, {
    CancelToken? cancelToken,
  });

  /// 初始化分片上传
  Future<InitiateMultipartUploadResult> initiateMultipartUpload(
    InitiateMultipartUploadRequest request, {
    CancelToken? cancelToken,
  });

  /// 上传分片
  Future<UploadPartResult> uploadPart(
    UploadPartRequest request, {
    CancelToken? cancelToken,
  });

  /// 完成分片上传
  Future<CompleteMultipartUploadResult> completeMultipartUpload(
    CompleteMultipartUploadRequest request, {
    CancelToken? cancelToken,
  });

  /// 取消分片上传
  Future<void> abortMultipartUpload(
    String key,
    String uploadId, {
    String? bucketName,
    CancelToken? cancelToken,
  });

  /// 上传本地文件并自动完成分片合并
  Future<CompleteMultipartUploadResult> multipartUploadFile(
    MultipartUploadFileRequest request, {
    CancelToken? cancelToken,
  });

  /// 批量分片上传本地文件
  Future<List<CompleteMultipartUploadResult>> multipartUploadFiles(
    MultipartUploadFilesRequest request, {
    CancelToken? cancelToken,
  });

  /// 列举执行中的分片上传任务
  Future<ListMultipartUploadsResult> listMultipartUploads(
    ListMultipartUploadsRequest request, {
    CancelToken? cancelToken,
  });

  /// 列举指定 uploadId 已上传的分片
  Future<ListPartsResult> listParts(
    ListPartsRequest request, {
    CancelToken? cancelToken,
  });

  /// 追加上传
  /// 对应阿里云 API: AppendObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/appendobject
  Future<AppendObjectResult> appendObject(AppendObjectRequest request,
      {CancelToken? cancelToken});

  /// 复制对象
  /// 对应阿里云 API: CopyObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/copyobject
  Future<CopyObjectResult> copyObject(CopyObjectRequest request,
      {CancelToken? cancelToken});

  /// 获取对象（字节流）
  /// 对应阿里云 API: GetObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/getobject
  Future<BytesResponse> getObject(GetObjectRequest request,
      {CancelToken? cancelToken});

  /// 获取对象元数据
  /// 对应阿里云 API: GetObjectMeta
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/getobjectmeta
  Future<ObjectMeta> getObjectMeta(String key,
      {String? bucketName, CancelToken? cancelToken});

  /// 判断对象是否存在
  /// 对应阿里云 API: HeadObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/headobject
  Future<bool> doesObjectExist(String key,
      {String? bucketName, CancelToken? cancelToken});

  /// 下载对象到本地文件
  /// 对应阿里云 API: GetObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/getobject
  Future<EmptyResponse> downloadObject(
    String key,
    String savePath, {
    String? bucketName,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// 删除对象
  /// 对应阿里云 API: DeleteObject
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/deleteobject
  Future<DeleteObjectResult> deleteObject(DeleteObjectRequest request,
      {CancelToken? cancelToken});

  /// 批量删除对象
  /// 对应阿里云 API: DeleteMultipleObjects
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/deletemultipleobjects
  Future<List<DeleteObjectResult>> deleteObjects(
    DeleteObjectsRequest request, {
    CancelToken? cancelToken,
  });

  // ==================== 签名 URL ====================

  /// 获取对象的临时签名 URL
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/signatures
  Future<String> getSignedUrl(
    String key, {
    String? bucketName,
    int expireSeconds = 60,
    Map<String, dynamic>? params,
  });

  /// 批量获取签名 URL
  Future<Map<String, String>> getSignedUrls(
    List<String> keys, {
    String? bucketName,
    int expireSeconds = 60,
  });

  // ==================== Bucket 操作 ====================

  /// 列举对象
  /// 对应阿里云 API: ListObjectsV2
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/listobjectsv2
  Future<ListObjectsResult> listObjects(
    ListObjectsRequest request, {
    String? bucketName,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// 列举所有 Bucket
  /// 对应阿里云 API: ListBuckets
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/listbuckets
  Future<ListBucketsResult> listBuckets(
    ListBucketsRequest request, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// 获取 Bucket 信息
  /// 对应阿里云 API: GetBucketInfo
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/getbucketinfo
  Future<BucketInfo> getBucketInfo(
      {String? bucketName, CancelToken? cancelToken});

  /// 获取 Bucket 统计
  /// 对应阿里云 API: GetBucketStat
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/getbucketstat
  Future<BucketStat> getBucketStat(
      {String? bucketName, CancelToken? cancelToken});

  /// 获取 Bucket ACL
  /// 对应阿里云 API: GetBucketAcl
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/getbucketacl
  Future<BucketAcl> getBucketAcl(
      {String? bucketName, CancelToken? cancelToken});

  /// 设置 Bucket ACL
  /// 对应阿里云 API: PutBucketAcl
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/putbucketacl
  Future<void> putBucketAcl(
    AclMode aclMode, {
    String? bucketName,
    CancelToken? cancelToken,
  });

  /// 获取 Bucket 策略
  /// 对应阿里云 API: GetBucketPolicy
  /// 文档: https://help.aliyun.com/zh/oss/user-guide/bucket-policy
  Future<String?> getBucketPolicy(
      {String? bucketName, CancelToken? cancelToken});

  /// 设置 Bucket 策略
  /// 对应阿里云 API: PutBucketPolicy
  /// 文档: https://help.aliyun.com/zh/oss/user-guide/bucket-policy
  Future<void> putBucketPolicy(
    Map<String, dynamic> policy, {
    String? bucketName,
    CancelToken? cancelToken,
  });

  /// 删除 Bucket 策略
  /// 对应阿里云 API: DeleteBucketPolicy
  /// 文档: https://help.aliyun.com/zh/oss/user-guide/bucket-policy
  Future<void> deleteBucketPolicy(
      {String? bucketName, CancelToken? cancelToken});

  // ==================== 地域操作 ====================

  /// 获取所有地域
  /// 对应阿里云 API: GetRegion
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/regions-endpoints
  Future<RegionsResult> getAllRegions({CancelToken? cancelToken});

  /// 获取指定地域
  /// 对应阿里云 API: GetRegion
  /// 文档: https://help.aliyun.com/zh/oss/developer-reference/regions-endpoints
  Future<RegionsResult> getRegion(String region, {CancelToken? cancelToken});
}
