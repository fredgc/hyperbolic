// Copyright 2026 Fred Gylys-Colwell.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:hyperbolic/l10n/l10n_extension.dart';
import 'package:hyperbolic/my_app.dart';

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
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    LocaleController.currentLocale.value = null;
  });

  group('Hyperbolic Internationalization & Localization Tests', () {
    testWidgets('App renders in English by default', (tester) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
      expect(find.byTooltip('Add Free Parameter'), findsOneWidget);
    });

    testWidgets('App renders in Spanish when Locale is es', (tester) async {
      LocaleController.currentLocale.value = const Locale('es');
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Añadir parámetro libre'), findsOneWidget);
    });

    testWidgets(
      'loadLocalizedHtmlAsset loads English and Spanish document content',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SizedBox()),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(SizedBox));

        final esAbout = await loadLocalizedHtmlAsset(context, 'about');
        expect(esAbout, contains('Herramienta de Dibujo Hiperbólico'));

        final esPrivacy = await loadLocalizedHtmlAsset(context, 'privacy');
        expect(esPrivacy, contains('Política de Privacidad'));

        final esTerms = await loadLocalizedHtmlAsset(context, 'terms');
        expect(esTerms, contains('Términos de Servicio'));
      },
    );

    testWidgets('Switching from Spanish to Auto (null) switches to English', (
      tester,
    ) async {
      await LocaleController.setLocale(const Locale('es'));
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Añadir parámetro libre'), findsOneWidget);

      await LocaleController.setLocale(null);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Add Free Parameter'), findsOneWidget);
    });

    testWidgets('App renders across all supported locales', (tester) async {
      for (final locale in LocaleController.supportedLocales) {
        LocaleController.currentLocale.value = locale;
        final app = MyApp.fullApp();
        app.manager.driveAccess.isTesting = true;
        await app.initialize();

        await tester.pumpWidget(app.build());
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.language_rounded), findsOneWidget);
      }
    });

    test('All localized ARB files maintain key parity with app_en.arb', () {
      final enContent = File('lib/l10n/app_en.arb').readAsStringSync();
      final enJson = jsonDecode(enContent) as Map<String, dynamic>;
      final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();

      final targetArbFiles = [
        'app_de.arb',
        'app_es.arb',
        'app_fr.arb',
        'app_ja.arb',
        'app_lt.arb',
        'app_pt.arb',
        'app_zh.arb',
      ];

      for (final file in targetArbFiles) {
        final content = File('lib/l10n/$file').readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        for (final key in enKeys) {
          expect(
            json.containsKey(key),
            isTrue,
            reason: 'ARB file $file is missing key "$key"',
          );
        }
      }
    });
  });
}
