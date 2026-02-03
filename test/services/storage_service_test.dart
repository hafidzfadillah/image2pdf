import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(AppConstants.storageChannel);
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

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
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/documents';
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  group('StorageService', () {
    test('savePdfToDownloads on Android calls specific method channel',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final bytes = Uint8List.fromList([1, 2, 3]);
      final fileName = 'test.pdf';

      // We expect this to try to write to a temp file first.
      // Since IO operations like File.writeAsBytes are hard to mock without
      // refactoring to use a file system abstraction or IOOverrides,
      // and checking strictly that might fail if the test environment fs is restricted.
      // However, /tmp usually exists.

      // For this test, valid temporary directory response '/tmp' is critical.
      // But 'File(/tmp/test.pdf).writeAsBytes' will run in the real FS.
      // We can use IOOverrides to intercept File operations if we want pure unit tests.
      // Or we can expect an error if /tmp is not writable in this env, but usually it is.

      // To avoid permission issues in CI/Test envs with real IO,
      // we'll see if it runs. If it fails on file write, we'll need IOOverrides.

      await IOOverrides.runZoned(() async {
        final result = await StorageService.savePdfToDownloads(bytes, fileName);

        expect(result, '/storage/emulated/0/Download/test.pdf');

        // Verify path provider was called to get temp dir
        expect(pathLog, isNotEmpty);
        expect(pathLog.first.method, 'getTemporaryDirectory');

        // Verify storage channel was called
        expect(log, hasLength(1));
        expect(log.first.method, AppConstants.savePdfMethod);
        expect(log.first.arguments['fileName'], fileName);
        expect(log.first.arguments['filePath'], '/tmp/$fileName');
      }, createFile: (path) => _MockFile(path));

      debugDefaultTargetPlatformOverride = null;
    });

    test('savePdfToDownloads on iOS saves to documents directory', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final bytes = Uint8List.fromList([1, 2, 3]);
      final fileName = 'test_ios.pdf';

      await IOOverrides.runZoned(() async {
        final result = await StorageService.savePdfToDownloads(bytes, fileName);

        expect(result, '/documents/$fileName'); // Based on our mock response

        // Verify path provider called for Documents
        expect(pathLog, isNotEmpty);
        expect(
            pathLog.any(
                (call) => call.method == 'getApplicationDocumentsDirectory'),
            isTrue);

        // Verify storage channel NOT called (iOS uses file io directly in this impl)
        expect(log, isEmpty);
      }, createFile: (path) => _MockFile(path));

      debugDefaultTargetPlatformOverride = null;
    });
  });
}

// Simple Mock File to avoid real IO
class _MockFile implements File {
  final String _path;
  _MockFile(this._path);

  @override
  String get path => _path;

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    return this;
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    return this;
  }

  // Implement other required members with stubs or throw UnimplementedError
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
