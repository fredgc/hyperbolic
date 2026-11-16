import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:hyperbolic/help.dart';
import 'package:hyperbolic/l10n/l10n_extension.dart';
import 'package:hyperbolic/my_app.dart';
import 'package:hyperbolic/scene/scene_view.dart';
import 'package:hyperbolic/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Hyperbolic Drawing Tool',
      packageName: 'org.gchouse.hyperbolic',
      version: '1.0.0',
      buildNumber: '3',
      buildSignature: 'signature',
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('Dark mode and theme cleanup tests', () {
    testWidgets('AppWidget reflects dark theme and button contrast', (
      tester,
    ) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      app.settings.theme.themeMode = ThemeMode.dark;
      app.settings.theme.updateAndCallback();
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final expectedSurface = ColorScheme.fromSeed(
        seedColor: app.settings.theme.themeColor.value,
        brightness: Brightness.dark,
      ).surface;
      final theme = Theme.of(tester.element(scaffoldFinder));
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, expectedSurface);
      expect(theme.scaffoldBackgroundColor, expectedSurface);

      final buttonStyle = theme.elevatedButtonTheme.style!;
      expect(
        buttonStyle.backgroundColor?.resolve({}),
        theme.colorScheme.primaryContainer,
      );
      expect(
        buttonStyle.foregroundColor?.resolve({}),
        theme.colorScheme.onPrimaryContainer,
      );
    });

    testWidgets('SettingsScreen reflects dark theme and button contrast', (
      tester,
    ) async {
      final settings = Settings();
      settings.addTheme();
      SceneView.initSettings(settings);
      settings.status = SettingsStatus.initialized;
      settings.theme.themeMode = ThemeMode.dark;
      settings.theme.update();

      await tester.pumpWidget(
        MaterialApp(
          theme: settings.theme.themeData,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(settings),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final expectedSurface = ColorScheme.fromSeed(
        seedColor: settings.theme.themeColor.value,
        brightness: Brightness.dark,
      ).surface;
      final theme = Theme.of(tester.element(scaffoldFinder));
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, expectedSurface);
      expect(theme.scaffoldBackgroundColor, expectedSurface);

      final buttonStyle = theme.elevatedButtonTheme.style!;
      expect(
        buttonStyle.backgroundColor?.resolve({}),
        theme.colorScheme.primaryContainer,
      );
      expect(
        buttonStyle.foregroundColor?.resolve({}),
        theme.colorScheme.onPrimaryContainer,
      );
    });

    test('HelpScreen.generateThemeCss injects ColorScheme hex colors', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.dark,
      );
      final css = HelpScreen.generateThemeCss(scheme);
      expect(css, contains('<style id="theme-style">'));
      expect(css, contains(HelpScreen.colorToHex(scheme.surface)));
      expect(css, contains(HelpScreen.colorToHex(scheme.onSurface)));
      expect(
        css,
        contains(HelpScreen.colorToHex(scheme.surfaceContainerHighest)),
      );
      expect(css, contains(HelpScreen.colorToHex(scheme.primary)));
      expect(css, contains(HelpScreen.colorToHex(scheme.outline)));
    });
  });
}
