# Release v1.1.0

发布日期：2026-05-15

## 版本亮点

- 新增 Multipart Upload 全流程支持，包括初始化、上传分片、完成上传、取消上传
- 新增单文件分片上传与批量分片上传高层封装
- 新增普通文件批量上传能力
- 新增自动上传策略，可按文件大小自动选择普通上传或分片上传
- 新增基于本地 checkpoint 的断点续传能力
- 新增分片任务查询接口，可列出未完成上传任务和已上传分片
- 补充中英文文档、example 示例和测试用例

## 新增能力

### Multipart Upload 底层接口

- `initiateMultipartUpload`
- `uploadPart`
- `completeMultipartUpload`
- `abortMultipartUpload`
- `listMultipartUploads`
- `listParts`

### 高层上传封装

- `multipartUploadFile`
- `multipartUploadFiles`
- `uploadFile`
- `uploadFiles`
- `putObjectFiles`

## 详细变更

### 上传能力增强

- 支持 OSS Multipart Upload 全流程
- 支持批量上传多个本地文件
- 支持批量分片上传多个大文件
- 支持根据文件大小自动切换普通上传和分片上传

### 断点续传

- 支持为分片上传保存本地 checkpoint
- 支持复用 `uploadId` 和已完成分片信息继续上传
- 文件大小或最后修改时间变化时自动丢弃旧 checkpoint
- 非断点续传模式下，分片上传失败时自动执行 `abortMultipartUpload`

### 查询能力

- 支持列出未完成的 Multipart Upload 任务
- 支持列出指定 `uploadId` 已上传的分片列表

### SDK 内部兼容性改进

- 修复 `?uploads` 这类无值查询参数的 URL 构造与签名兼容问题
- 补充分片上传相关请求模型与结果模型
- 统一自动上传返回模型，便于上层判断实际上传模式

## 文档与示例

- `README.md` 新增 Multipart Upload、自动上传、断点续传、批量上传示例
- `README_EN.md` 同步补充英文版说明
- `example/lib/main.dart` 新增自动上传、批量自动上传、显式分片上传示例按钮

## 测试

- 新增 Multipart XML 解析测试
- 新增 checkpoint 保存、加载和失效清理测试
- 已通过 `dart analyze`
- 已通过 `flutter test test/src`

## 兼容性说明

- 保持现有普通上传接口可用
- 新能力以新增接口为主，不影响已有调用方式
- 开启 `resumable` 后会在本地生成 checkpoint 文件

## 提交信息

- 标签：`v1.1.0`
- 提交：`ca0a376`

