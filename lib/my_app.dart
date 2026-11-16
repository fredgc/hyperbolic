import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'file_manager.dart';
import 'help.dart';
import 'js_stub.dart' if (dart.library.html) 'js_interface.dart';
import 'l10n/l10n_extension.dart';
import 'navigation.dart';
import 'printer.dart';
import 'scene.dart';
import 'settings.dart';
import 'widget.dart';

class MyApp {
  final Settings settings;
  final FileManager manager;
  late final GoRouter router;

  MyApp(this.settings, this.manager, String initialLocation) {
    router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(path: '/scene', builder: makeSplash, onExit: onExit),
        GoRoute(path: '/settings', builder: makeSettings),
        GoRoute(path: '/help', builder: makeHelp),
        GoRoute(path: '/about', builder: makeHelp),
        GoRoute(path: '/privacy', builder: makeHelp),
        GoRoute(path: '/terms', builder: makeHelp),
      ],
      errorBuilder: errorBuilder,
    );
  }

  factory MyApp.fullApp() {
    final settings = Settings();
    final manager = FileManager(settings);
    return MyApp(settings, manager, '/scene');
  }

  Future<void> initialize() async {
    settings.addTheme();
    SceneView.initSettings(settings);
    initJavascriptInterface();

    settings.initDebug();
    SceneView.initDebugSettings(settings);
    Log.initSettings(settings);

    await settings.initialize();

    manager.initialize();
  }

  Widget build() {
    return StreamBuilder<SettingsStatus>(
      stream: settings.statusStream(),
      builder: (context, snapshot) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.currentLocale,
          builder: (context, locale, _) {
            return MaterialApp.router(
              locale: locale,
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                if (deviceLocale != null) {
                  for (final supported in supportedLocales) {
                    if (supported.languageCode == deviceLocale.languageCode) {
                      return supported;
                    }
                  }
                }
                return const Locale('en');
              },
              onGenerateTitle: (context) => context.l10n.appTitle,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: settings.theme.themeData,
              darkTheme: settings.theme.themeData,
              themeMode: settings.theme.themeMode,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                final mediaQueryData = MediaQuery.of(context);
                final browserFontSize = getBrowserRootFontSize();
                final scaleFactor = browserFontSize / 16.0;
                final textScaler = scaleFactor != 1.0
                    ? TextScaler.linear(scaleFactor)
                    : mediaQueryData.textScaler;
                return MediaQuery(
                  data: mediaQueryData.copyWith(textScaler: textScaler),
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget makeSettings(BuildContext context, GoRouterState state) {
    fixAddressBar(context, '/settings');
    return SettingsScreen(settings);
  }

  Widget makeHelp(BuildContext context, GoRouterState state) {
    String initialPage = 'about.html';
    if (state.uri.path == '/about') {
      initialPage = 'about.html';
      fixAddressBar(context, '/about');
    } else if (state.uri.path == '/privacy') {
      initialPage = 'privacy.html';
      fixAddressBar(context, '/privacy');
    } else if (state.uri.path == '/terms') {
      initialPage = 'terms.html';
      fixAddressBar(context, '/terms');
    } else {
      initialPage = state.uri.queryParameters['page'] ?? 'overview.html';
      fixAddressBar(context, state.uri.toString());
    }
    return HelpScreen(settings, initialPage: initialPage);
  }

  Widget errorBuilder(BuildContext context, GoRouterState state) {
    return makeSplash(context, state);
  }

  int _sceneCount = 0;
  Widget makeSplash(BuildContext context, GoRouterState state) {
    _sceneCount++;
    manager.setContext('scene $_sceneCount', context);
    fixAddressBar(context, state.uri.toString());
    manager.checkNavigation(state.uri.queryParameters);
    return SplashWidget(settings, manager);
  }

  FutureOr<bool> onExit(BuildContext context, GoRouterState state) async {
    return await manager.checkSave(context);
  }
}
