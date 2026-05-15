# v1.1.0

- Added Multipart Upload support, including initiate, upload part, complete, abort, list uploads, and list parts
- Added high-level helpers for `multipartUploadFile` and `multipartUploadFiles`
- Added batch upload support for normal files and multipart files
- Added `uploadFile` and `uploadFiles` to auto-select simple or multipart upload by file size
- Added resumable multipart upload with local checkpoint support
- Added examples, README updates, and tests for multipart upload and checkpoint flows
