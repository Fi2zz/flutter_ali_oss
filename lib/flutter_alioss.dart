// flutter_alioss -- 阿里云对象存储服务（OSS）Flutter SDK
// 基于阿里云 OSS REST API 构建
// 阿里云 OSS 首页: https://www.aliyun.com/product/oss
// 开发者文档: https://help.aliyun.com/zh/oss/developer-reference/overview
// API 功能列表: https://help.aliyun.com/zh/oss/developer-reference/list-of-operations-by-function
/// Flutter SDK for Alibaba Cloud Object Storage Service (OSS).
library flutter_alioss;

export 'src/client.dart';
export 'src/client_api.dart' show ProgressCallback;
export 'src/model/auth.dart';
export 'src/model/bucket.dart';
export 'src/model/callback.dart';
export 'src/model/common_prefix.dart';
export 'src/model/enums.dart';
export 'src/model/oss_object.dart';
export 'src/model/owner.dart';
export 'src/model/region.dart';
export 'src/model/request/append_object_request.dart';
export 'src/model/request/copy_object_request.dart';
export 'src/model/request/delete_object_request.dart';
export 'src/model/request/get_object_request.dart';
export 'src/model/request/list_buckets_request.dart';
export 'src/model/request/list_objects_request.dart';
export 'src/model/request/put_object_request.dart';
export 'src/model/result/append_object_result.dart';
export 'src/model/result/bucket_acl.dart';
export 'src/model/result/bucket_info.dart';
export 'src/model/result/bucket_stat.dart';
export 'src/model/result/copy_object_result.dart';
export 'src/model/result/delete_object_result.dart';
export 'src/model/result/list_buckets_result.dart';
export 'src/model/result/list_objects_result.dart';
export 'src/model/result/object_meta.dart';
export 'src/model/result/put_object_result.dart';
export 'src/model/result/regions_result.dart';
export 'src/util/cancel_token.dart';
export 'src/util/oss_exception.dart';
export 'src/util/oss_response.dart';
