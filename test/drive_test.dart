import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/drive/v3.dart' show File, Media;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:hyperbolic/drive.dart';
import 'package:hyperbolic/my_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('Drive subsystem unit tests', () {
    test('TokenStorage saveCredentials and getTokens', () async {
      final expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
      final credentials = auth.AccessCredentials(
        auth.AccessToken('Bearer', 'test_access_token', expiry),
        'test_refresh_token',
        [MyDriveAccess.scopes.first],
        idToken: 'test_id_token',
      );

      await TokenStorage.saveCredentials(credentials);
      final tokens = await TokenStorage.getTokens();

      expect(tokens, isNotNull);
      expect(tokens!['access_token'], equals('test_access_token'));
      expect(tokens['refresh_token'], equals('test_refresh_token'));
      expect(tokens['id_token'], equals('test_id_token'));
      expect(tokens['expiry_date'], equals(expiry.toIso8601String()));
    });

    test('TokenStorage clearTokens', () async {
      final expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
      final credentials = auth.AccessCredentials(
        auth.AccessToken('Bearer', 'test_access_token', expiry),
        'test_refresh_token',
        [MyDriveAccess.scopes.first],
      );

      await TokenStorage.saveCredentials(credentials);
      expect(await TokenStorage.getTokens(), isNotNull);

      await TokenStorage.clearTokens();
      expect(await TokenStorage.getTokens(), isNull);
      expect(await TokenStorage.getUserInfo(), isNull);
    });

    test('buildDriveQuery handles search terms and owner filters', () {
      expect(buildDriveQuery(''), equals(''));
      expect(buildDriveQuery('my_scene'), equals("name contains 'my_scene'"));
      expect(buildDriveQuery('owner:me'), equals("'me' in owners"));
      expect(
        buildDriveQuery('owner:test@example.com triangle'),
        equals("'test@example.com' in owners and name contains 'triangle'"),
      );
    });

    test('MyDriveAccess MIME type is application/hyperbolic', () {
      expect(MyDriveAccess.mimeType, equals('application/hyperbolic'));
    });

    test('DriveHolder create and initial properties', () {
      final holder = DriveHolder.create();
      expect(holder.type, equals('drive'));
      expect(holder.id, equals('_new_'));
      expect(holder.path, equals('/scene?drive=_new_'));
      expect(holder.skipRecent, isFalse);
    });

    test('DriveHolder saveData creates new file via driveAccess', () async {
      final app = MyApp.fullApp();
      final mockAccess = TestMockDriveAccess();
      app.manager.driveAccess = mockAccess;

      final holder = DriveHolder.create();
      holder.title = 'Hyperbolic Tessellation';

      const jsonContent =
          '{"title": "Hyperbolic Tessellation", "description": "Poincaré Disk model"}';
      final success = await holder.saveData(jsonContent, app.manager);

      expect(success, isTrue);
      expect(holder.id, equals('created_drive_file_id'));
      expect(mockAccess.lastCreatedName, equals('Hyperbolic Tessellation'));
    });

    test('DriveHolder loadData retrieves content stream', () async {
      final app = MyApp.fullApp();
      final mockAccess = TestMockDriveAccess();
      app.manager.driveAccess = mockAccess;

      final holder = DriveHolder('existing_id');
      final content = await holder.loadData(app.manager);

      expect(content, contains('mock_content'));
      expect(holder.title, equals('Remote Diagram'));
    });

    test('DriveHolder loadData throws when unauthenticated', () async {
      final app = MyApp.fullApp();
      final mockAccess = TestMockDriveAccess()..authenticated = false;
      app.manager.driveAccess = mockAccess;

      final holder = DriveHolder('missing_id');
      expect(() => holder.loadData(app.manager), throwsA(isA<Exception>()));
    });
  });
}

class TestMockDriveAccess extends MyDriveAccess {
  bool authenticated = true;
  String? lastCreatedName;

  TestMockDriveAccess() {
    isTesting = true;
    if (authenticated) {
      status = DriveAccessStatus.authorized;
    }
  }

  @override
  DriveAccessStatus get status => authenticated
      ? DriveAccessStatus.authorized
      : DriveAccessStatus.loggedOut;

  @override
  Future<File?> newFile(
    BuildContext? context,
    String title,
    String description,
    Media media,
  ) async {
    lastCreatedName = title;
    return File(
      id: 'created_drive_file_id',
      name: title,
      description: description,
    );
  }

  @override
  Future<File?> getFileById(BuildContext? context, String id) async {
    if (!authenticated) return null;
    return File(id: id, name: 'Remote Diagram');
  }

  @override
  Future<Media?> loadData(BuildContext? context, File file) async {
    if (!authenticated) return null;
    final bytes = '{"data": "mock_content"}'.codeUnits;
    return Media(Stream.value(bytes), bytes.length);
  }
}
