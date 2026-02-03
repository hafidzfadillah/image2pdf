import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(AppConstants.storageChannel);
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel permissionChannel =
      MethodChannel('flutter.baseflow.com/permissions/methods');

  final List<MethodCall> log = <MethodCall>[];
  final List<MethodCall> pathLog = <MethodCall>[];

  setUp(() {
    log.clear();
    pathLog.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == AppConstants.savePdfMethod) {
        return '/storage/emulated/0/Download/${methodCall.arguments['fileName']}';
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel,
            (MethodCall methodCall) async {
      pathLog.add(methodCall);
      if (methodCall.method == 'getTemporaryDirectory') {
        return '/tmp';
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel,
            (MethodCall methodCall) async {
      // Mock permission granted
      if (methodCall.method == 'checkPermissionStatus') {
        return 1; // Granted
      }
      if (methodCall.method == 'requestPermissions') {
        // Return map of permission -> status (1=granted)
        // Arguments is a list of permissions integers
        final List proxied = methodCall.arguments;
        return Map.fromIterable(proxied, value: (_) => 1);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
  });

  // A minimal valid JPG header/bytes to satisfy image decoders if needed,
  final Uint8List dummyImageBytes = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  group('PdfService', () {
    test('generatePdfFromImages creates PDF and saves it (Android)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await IOOverrides.runZoned(() async {
        final mockFile = _MockFile('/tmp/img1.jpg', dummyImageBytes);
        final files = [mockFile];

        final result = await PdfService.generatePdfFromImages(files);

        // Verify result
        expect(result.pageCount, 1);
        expect(result.fileName, startsWith(AppConstants.pdfFileNamePrefix));
        expect(result.savedPath, contains('/Download/'));

        // Verify interactions
        // 1. Should have requested path for temp file (for preview creation)
        expect(pathLog.any((call) => call.method == 'getTemporaryDirectory'),
            isTrue);

        // 2. Should have called storage channel to save
        expect(log, hasLength(1));
        expect(log.first.method, AppConstants.savePdfMethod);
      }, createFile: (path) => _MockFile(path, dummyImageBytes));

      debugDefaultTargetPlatformOverride = null;
    });

    test('generatePdfFromImages throws on empty list', () async {
      expect(
        () => PdfService.generatePdfFromImages([]),
        throwsException,
      );
    });
  });
}

class _MockFile implements File {
  final String _path;
  final Uint8List? _readBytes;

  _MockFile(this._path, [this._readBytes]);

  @override
  String get path => _path;

  @override
  Future<Uint8List> readAsBytes() async {
    return _readBytes ?? Uint8List(0);
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    return this;
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
