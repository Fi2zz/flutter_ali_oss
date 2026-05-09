// 阿里云 OSS 枚举类型
// ACL 文档: https://help.aliyun.com/zh/oss/user-guide/acls
// 存储类型文档: https://help.aliyun.com/zh/oss/user-guide/overview-of-storage-classes

/// 阿里云 OSS 访问控制（ACL）枚举
/// 对应 x-oss-object-acl / x-oss-acl HTTP 头
///
/// === 阿里云 ACL 说明 ===
/// - private: 私有，只有所有者可以读写
/// - public-read: 公共读，所有人可读，仅所有者可写
/// - public-read-write: 公共读写，所有人可读写（不推荐）
/// - default: 默认，继承 Bucket ACL
///
/// 文档: https://help.aliyun.com/zh/oss/user-guide/acls
enum AclMode {
  /// 公共读写
  /// 阿里云值: "public-read-write"
  publicWrite("public-read-write"),

  /// 公共读
  /// 阿里云值: "public-read"
  publicRead("public-read"),

  /// 私有
  /// 阿里云值: "private"
  private("private"),

  /// 默认（继承 Bucket ACL）
  /// 阿里云值: "default"
  inherited("default");

  final String content;

  const AclMode(this.content);
}

/// 阿里云 OSS 存储类型枚举
/// 对应 x-oss-storage-class HTTP 头
///
/// === 阿里云存储类型说明 ===
/// - STANDARD: 标准存储，适合频繁访问的图片、视频、文件
/// - IA: 低频访问，适合月均访问 1-2 次的备份数据
/// - Archive: 归档存储，适合长期归档、需解冻后访问
/// - ColdArchive: 冷归档存储，适合超长期冷归档
///
/// 文档: https://help.aliyun.com/zh/oss/user-guide/overview-of-storage-classes
enum StorageType {
  /// 标准存储
  /// 阿里云值: "Standard"
  standard("Standard", "标准存储"),

  /// 低频访问
  /// 阿里云值: "IA"
  ia("IA", "低频访问"),

  /// 归档存储
  /// 阿里云值: "Archive"
  archive("Archive", "归档存储"),

  /// 冷归档存储
  /// 阿里云值: "ColdArchive"
  coldArchive("ColdArchive", "冷归档存储");

  final String content;
  final String name;

  const StorageType(this.content, this.name);
}

/// 阿里云 OSS 回调请求体类型枚举
/// 对应 x-oss-callback 头中的 callbackBodyType 字段
///
/// === 阿里云回调说明 ===
/// - application/x-www-form-urlencoded: URL 编码形式
/// - application/json: JSON 形式
///
/// 文档: https://help.aliyun.com/zh/oss/developer-reference/callback
enum CallbackBodyType {
  /// URL 编码形式
  /// 阿里云值: "application/x-www-form-urlencoded"
  url("application/x-www-form-urlencoded"),

  /// JSON 形式
  /// 阿里云值: "application/json"
  json("application/json");

  final String contentType;

  const CallbackBodyType(this.contentType);
}

/// 拼写兼容别名（原包中此枚举拼写错误）
/// 请使用 [CallbackBodyType]
@Deprecated('Use CallbackBodyType instead')
typedef CalbackBodyType = CallbackBodyType;
