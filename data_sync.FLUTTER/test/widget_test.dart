// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:data_sync_flutter/models/settings.dart';
import 'package:data_sync_flutter/screens/settings_page.dart';
import 'package:data_sync_flutter/screens/sync_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;

void main() {
  late ByteData fontByteData;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontFile = await _findSystemFontFile();
    final fontBytes = await fontFile.readAsBytes();
    fontByteData = ByteData.sublistView(fontBytes);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          if (message == null) {
            return null;
          }

          final assetKey = String.fromCharCodes(message.buffer.asUint8List());
          if (assetKey.startsWith('google_fonts/')) {
            return ByteData.sublistView(fontByteData.buffer.asUint8List());
          }

          return null;
        });
  });

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    google_fonts_base.clearCache();
    google_fonts_base.assetManifest = _FakeAssetManifest();
  });

  testWidgets('App shows polished sync and settings pages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SyncPage(loadSettings: () async => Settings())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bereit fuer den ersten Abgleich'), findsOneWidget);
  });

  testWidgets('Settings page shows the configuration overview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(loadSettings: () async => Settings())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Alles Wichtige an einem Ort'), findsOneWidget);
    expect(find.text('Konfiguration'), findsOneWidget);
  });

  testWidgets('Setup hint disappears when API URL and sync directory exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SyncPage(
          loadSettings: () async => Settings(
            apiUrl: 'https://example.test',
            syncPath: '/tmp/data_sync',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bereit fuer den ersten Abgleich'), findsNothing);
  });
}

class _FakeAssetManifest implements AssetManifest {
  @override
  List<String> listAssets() => const [
    'google_fonts/Inter-Regular.ttf',
    'google_fonts/Inter-Medium.ttf',
    'google_fonts/Inter-SemiBold.ttf',
    'google_fonts/Inter-Bold.ttf',
    'google_fonts/JetBrainsMono-Regular.ttf',
  ];

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

Future<File> _findSystemFontFile() async {
  final result = await Process.run('fc-match', ['-f', '%{file}\n', 'sans']);
  if (result.exitCode == 0) {
    final fontPath = (result.stdout as String).trim();
    final fontFile = File(fontPath);
    if (fontPath.isNotEmpty && await fontFile.exists()) {
      return fontFile;
    }
  }

  final fallbackPaths = [
    '/usr/share/fonts/noto/NotoSans-Regular.ttf',
    '/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf',
    '/usr/share/fonts/TTF/DejaVuSans.ttf',
  ];

  for (final path in fallbackPaths) {
    final fontFile = File(path);
    if (await fontFile.exists()) {
      return fontFile;
    }
  }

  throw Exception('Kein Systemfont fuer Widget-Tests gefunden.');
}
