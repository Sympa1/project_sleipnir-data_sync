import 'dart:io';

import 'package:data_sync_flutter/services/file_scanner_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scanFiles ignores git metadata directories', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'data_sync_scanner_test_',
    );

    try {
      final visibleDirectory = Directory('${tempDirectory.path}/docs');
      await visibleDirectory.create(recursive: true);
      await File('${visibleDirectory.path}/guide.txt').writeAsString('visible');

      final gitObjectsDirectory = Directory(
        '${tempDirectory.path}/.git/objects/pack',
      );
      await gitObjectsDirectory.create(recursive: true);
      await File('${gitObjectsDirectory.path}/pack-test.pack').writeAsString(
        'git metadata',
      );

      final scannerService = FileScannerService();
      final scannedFiles = await scannerService.scanFiles(tempDirectory.path);

      expect(scannedFiles.map((file) => file.relativePath), ['docs/guide.txt']);
    } finally {
      await tempDirectory.delete(recursive: true);
    }
  });
}
