import 'package:flutter_alioss/flutter_alioss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ListObjectsRequest parameters", () {
    test("default values", () {
      const request = ListObjectsRequest();
      final params = request.toParameters();
      expect(params['max-keys'], '100');
      expect(params.containsKey('prefix'), false);
    });

    test("with prefix", () {
      const request = ListObjectsRequest(prefix: "images/", maxKeys: 10);
      final params = request.toParameters();
      expect(params['prefix'], 'images/');
      expect(params['max-keys'], '10');
    });
  });

  group("AclMode values", () {
    test("match OSS values", () {
      expect(AclMode.private.content, "private");
      expect(AclMode.publicRead.content, "public-read");
      expect(AclMode.publicWrite.content, "public-read-write");
      expect(AclMode.inherited.content, "default");
    });
  });

  group("StorageType values", () {
    test("match OSS values", () {
      expect(StorageType.standard.content, "Standard");
      expect(StorageType.ia.content, "IA");
      expect(StorageType.archive.content, "Archive");
      expect(StorageType.coldArchive.content, "ColdArchive");
    });
  });
}
