import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart' show rootBundle;
import 'webview_stub.dart' if (dart.library.html) 'webview_web.dart';

import "printer.dart";
import 'l10n/l10n_extension.dart';
import 'settings.dart';
import 'navigation.dart';

class HelpScreen extends StatefulWidget {
  final Settings settings;
  final String initialPage;
  static const routeName = "/help";
  const HelpScreen(this.settings, {this.initialPage = "about.html", super.key});

  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String generateThemeCss(ColorScheme scheme) {
    final bgHex = colorToHex(scheme.surface);
    final textHex = colorToHex(scheme.onSurface);
    final sectionHex = colorToHex(scheme.surfaceContainerHighest);
    final primaryHex = colorToHex(scheme.primary);
    final borderHex = colorToHex(scheme.outline);

    return '''
<style id="theme-style">
html, body, .container {
  background: $bgHex !important;
  color: $textHex !important;
}
section {
  background: $sectionHex !important;
  border: 1px solid $borderHex !important;
  color: $textHex !important;
}
h1, h2, h3, h4, .title {
  color: $primaryHex !important;
}
p, li, td, th {
  color: $textHex !important;
}
table, th, td {
  border-color: $borderHex !important;
}
th {
  background: $sectionHex !important;
  color: $primaryHex !important;
}
a {
  color: $primaryHex !important;
}
a:visited {
  color: $primaryHex !important;
}
a:hover {
  color: $textHex !important;
}
code {
  background: $sectionHex !important;
  color: $textHex !important;
  padding: 2px 4px !important;
  border-radius: 4px !important;
}
nav {
  background-color: $sectionHex !important;
}
header, footer {
  background: inherit !important;
  color: $textHex !important;
}
</style>
''';
  }

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late final WebViewController webViewController;
  double progress = 0;
  String _currentFilename = "about.html";
  bool _isMenuOpen = false;
  Brightness? _lastLoadedBrightness;
  Color? _lastLoadedSurface;
  Color? _lastLoadedPrimary;
  late final StreamSubscription<SettingsStatus> _settingsListener;

  @override
  void initState() {
    super.initState();
    _currentFilename = widget.initialPage;
    if (kIsWeb) {
      initWebviewPlatform();
    }
    webViewController = WebViewController();
    try {
      webViewController.setBackgroundColor(
        widget.settings.theme.themeData.colorScheme.surface,
      );
    } catch (e) {
      // Ignored if unsupported on the platform/test environment
    }
    if (!kIsWeb) {
      NavigationDelegate delegate;
      try {
        delegate = NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              this.progress = progress / 100.0;
            });
          },
          onPageFinished: (String url) {
            _applyTheme();
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith("http")) {
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        );
      } catch (e) {
        delegate = NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              this.progress = progress / 100.0;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith("http")) {
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        );
      }
      webViewController
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(delegate);
    }
    _settingsListener = widget.settings.statusStream().listen((status) {
      if (mounted) {
        setState(() {});
        _checkAndReloadTheme();
      }
    });
    LocaleController.currentLocale.addListener(_onLocaleChanged);
    loadHelpFile(_currentFilename);
  }

  void _onLocaleChanged() {
    if (mounted) {
      setState(() {});
      loadHelpFile(_currentFilename);
    }
  }

  @override
  void dispose() {
    LocaleController.currentLocale.removeListener(_onLocaleChanged);
    _settingsListener.cancel();
    super.dispose();
  }

  void _applyTheme() {
    bool isDark = widget.settings.theme.scheme.brightness == Brightness.dark;
    String js = isDark
        ? "document.documentElement.classList.add('dark-theme'); document.documentElement.classList.remove('light-theme');"
        : "document.documentElement.classList.add('light-theme'); document.documentElement.classList.remove('dark-theme');";
    webViewController.runJavaScript(js).catchError((e) {
      Log.help.log("Error injecting theme JS: $e");
    });
  }

  void _checkAndReloadTheme() {
    final scheme = widget.settings.theme.scheme;
    if (_lastLoadedBrightness != scheme.brightness ||
        _lastLoadedSurface != scheme.surface ||
        _lastLoadedPrimary != scheme.primary) {
      try {
        webViewController.setBackgroundColor(scheme.surface);
      } catch (e) {
        // Ignored on platforms not supporting setBackgroundColor.
      }
      loadHelpFile(_currentFilename);
      _applyTheme();
    }
  }

  @override
  void didUpdateWidget(HelpScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPage != oldWidget.initialPage) {
      _currentFilename = widget.initialPage;
      loadHelpFile(_currentFilename);
    }
  }

  void loadHelpFile(String filename) async {
    final scheme = widget.settings.theme.scheme;
    _lastLoadedBrightness = scheme.brightness;
    _lastLoadedSurface = scheme.surface;
    _lastLoadedPrimary = scheme.primary;
    final cleanBase = filename.replaceAll(RegExp(r'_[a-z]{2}\.html$'), '.html');
    _currentFilename = cleanBase;
    try {
      final active = LocaleController.currentLocale.value?.languageCode;
      final systemLang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final supportedCodes = LocaleController.supportedLocales
          .map((l) => l.languageCode)
          .toSet();
      final lang = (active != null && active.isNotEmpty)
          ? active
          : (supportedCodes.contains(systemLang) ? systemLang : 'en');
      String targetFilename = cleanBase;
      if (lang != 'en' &&
          cleanBase.endsWith('.html') &&
          !cleanBase.contains('_$lang.html')) {
        final candidate = cleanBase.replaceFirst('.html', '_$lang.html');
        const localizedDocs = {
          'about.html',
          'controls.html',
          'files.html',
          'objects.html',
          'overview.html',
          'privacy.html',
          'terms.html',
        };
        if (localizedDocs.contains(cleanBase)) {
          targetFilename = candidate;
        }
      }

      String htmlContent;
      String cssContent;
      if (kIsWeb) {
        final versionTag =
            '${widget.settings.version}+${widget.settings.buildNumber}';
        final htmlUri = Uri.parse(
          'assets/assets/$targetFilename?v=$versionTag',
        );
        final cssUri = Uri.parse(
          'assets/assets/css/doc_style.css?v=$versionTag',
        );

        var htmlResponse = await http.get(htmlUri);
        final cssResponse = await http.get(cssUri);

        if (htmlResponse.statusCode != 200 && targetFilename != cleanBase) {
          targetFilename = cleanBase;
          htmlResponse = await http.get(
            Uri.parse('assets/assets/$cleanBase?v=$versionTag'),
          );
        }

        if (htmlResponse.statusCode == 200) {
          htmlContent = utf8.decode(htmlResponse.bodyBytes);
        } else {
          try {
            htmlContent = await rootBundle.loadString('assets/$targetFilename');
          } catch (_) {
            htmlContent = await rootBundle.loadString('assets/$cleanBase');
          }
        }

        if (cssResponse.statusCode == 200) {
          cssContent = utf8.decode(cssResponse.bodyBytes);
        } else {
          cssContent = await rootBundle.loadString('assets/css/doc_style.css');
        }
      } else {
        try {
          htmlContent = await rootBundle.loadString('assets/$targetFilename');
        } catch (_) {
          htmlContent = await rootBundle.loadString('assets/$cleanBase');
        }
        cssContent = await rootBundle.loadString('assets/css/doc_style.css');
      }

      // Ensure external links and /version5/ links open in the top browser tab/window
      // rather than inside the srcdoc iframe or triggering Flutter's SPA router.
      final anchorTargetRegExp = RegExp(
        r'<a\s+href="(https?://[^"]+|/version5/[^"]*)"(?![^>]*\btarget=)',
      );
      htmlContent = htmlContent.replaceAllMapped(anchorTargetRegExp, (match) {
        return '<a href="${match.group(1)}" target="_blank" rel="noopener"';
      });

      // Clean up any <pre class="mermaid"><code> blocks to prevent Mermaid syntax error.
      final mermaidRegExp = RegExp(
        r'<pre class="mermaid"><code>([\s\S]*?)</code></pre>',
      );
      htmlContent = htmlContent.replaceAllMapped(mermaidRegExp, (match) {
        return '<pre class="mermaid">${match.group(1)}</pre>';
      });

      // Replace stylesheet link with inlined CSS to avoid relative path loading issues on web and mobile.
      final linkRegExp = RegExp(
        r'''<link\s+rel=["']stylesheet["']\s+href=["'][^"']*doc_style\.css["']\s*/?>''',
      );
      final themeCss = HelpScreen.generateThemeCss(scheme);
      final combinedCss = '<style>$cssContent</style>$themeCss';
      if (htmlContent.contains(linkRegExp)) {
        htmlContent = htmlContent.replaceFirst(linkRegExp, combinedCss);
      } else if (htmlContent.contains('</head>')) {
        htmlContent = htmlContent.replaceFirst(
          '</head>',
          '$combinedCss</head>',
        );
      } else {
        htmlContent = '<head>$combinedCss</head>$htmlContent';
      }

      bool isDark = _lastLoadedBrightness == Brightness.dark;
      if (isDark) {
        // Change mermaid theme to dark.
        htmlContent = htmlContent.replaceFirst(
          "theme: 'default'",
          "theme: 'dark'",
        );
        htmlContent = htmlContent.replaceFirst(
          'theme: "default"',
          'theme: "dark"',
        );

        if (htmlContent.contains("<html")) {
          htmlContent = htmlContent.replaceFirst(
            "<html",
            "<html class=\"dark-theme\"",
          );
        } else if (htmlContent.contains("<body")) {
          htmlContent = htmlContent.replaceFirst(
            "<body",
            "<body class=\"dark-theme\"",
          );
        }
      } else {
        // Change mermaid theme to default.
        htmlContent = htmlContent.replaceFirst(
          "theme: 'dark'",
          "theme: 'default'",
        );
        htmlContent = htmlContent.replaceFirst(
          'theme: "dark"',
          'theme: "default"',
        );

        if (htmlContent.contains("<html")) {
          htmlContent = htmlContent.replaceFirst(
            "<html",
            "<html class=\"light-theme\"",
          );
        } else if (htmlContent.contains("<body")) {
          htmlContent = htmlContent.replaceFirst(
            "<body",
            "<body class=\"light-theme\"",
          );
        }
      }
      await webViewController.loadHtmlString(htmlContent);
    } catch (e) {
      Log.help.log("Error loading help file: $e");
    }
  }

  AppBar appBar(BuildContext context, {required bool isWideScreen}) {
    // Log.help.log("Building appbar.");
    return AppBar(
      title: Text(
        (!isWideScreen && _isMenuOpen)
            ? context.l10n.helpMenu
            : context.l10n.helpAndDocs,
      ),
      leading: isWideScreen
          ? null
          : IconButton(
              icon: Icon(_isMenuOpen ? Icons.close : Icons.menu),
              tooltip: _isMenuOpen
                  ? context.l10n.menuCloseMenu
                  : context.l10n.openDrawerTooltip,
              onPressed: () {
                setState(() {
                  _isMenuOpen = !_isMenuOpen;
                });
              },
            ),
      automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: context.l10n.settingsTooltip,
          onPressed: () {
            context.push(SettingsScreen.routeName);
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.l10n.closeTooltip,
          onPressed: () {
            // Log.help.log("CYAN: help close.");
            popOrHome(context);
          },
        ),
      ],
    );
  }

  Widget buildNavigationList(BuildContext context, {required bool isSidebar}) {
    List<Widget> items = [
      if (isSidebar) ...[
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Text(
            context.l10n.appTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
      ] else ...[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                context.l10n.appTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.helpAndDocs,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
        child: Text(
          context.l10n.userGuidesSection,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      buildDrawerItem(
        context,
        context.l10n.aboutHyperbolic,
        "about.html",
        Icons.info_outline,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        context.l10n.privacyPolicy,
        "privacy.html",
        Icons.privacy_tip_outlined,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        context.l10n.termsOfService,
        "terms.html",
        Icons.gavel_outlined,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        context.l10n.overview,
        "overview.html",
        Icons.visibility_outlined,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        context.l10n.toolbarAndSliders,
        "controls.html",
        Icons.tune,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        context.l10n.hyperbolicObjects,
        "objects.html",
        Icons.category_outlined,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        context.l10n.hyperbolicGeometry,
        "transformations.html",
        Icons.transform,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        context.l10n.fileManagement,
        "files.html",
        Icons.folder_open_outlined,
        isSidebar: isSidebar,
      ),
    ];
    if (Settings.kDebugEnabled && Settings.debugEnabled) {
      items.addAll([
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            "Developer Docs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        buildDrawerItem(
          context,
          "Readme",
          "dev/README.html",
          Icons.description_outlined,
          isSidebar: isSidebar,
        ),
        buildDrawerItem(
          context,
          "Developer Guide",
          "dev/GEMINI.html",
          Icons.code_outlined,
          isSidebar: isSidebar,
        ),
        buildDrawerItem(
          context,
          "Project Plan",
          "dev/plan.html",
          Icons.assignment_outlined,
          isSidebar: isSidebar,
        ),
        buildDrawerItem(
          context,
          "Tutorial Plan",
          "dev/tutorial_plan.html",
          Icons.assignment_outlined,
          isSidebar: isSidebar,
        ),
      ]);
    }
    return ListView(padding: EdgeInsets.zero, children: items);
  }

  Widget buildDrawerItem(
    BuildContext context,
    String title,
    String filename,
    IconData icon, {
    required bool isSidebar,
  }) {
    final isSelected = _currentFilename == filename;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        if (!isSidebar) {
          setState(() {
            _isMenuOpen = false;
          });
        }
        setState(() {
          _currentFilename = filename;
        });
        loadHelpFile(filename);
      },
    );
  }

  Widget webview(BuildContext c) {
    return WebViewWidget(controller: webViewController);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 750;
    return Scaffold(
      appBar: appBar(context, isWideScreen: isWideScreen),
      body: SafeArea(
        child: isWideScreen
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 280,
                    child: Material(
                      color: Theme.of(context).cardColor,
                      child: buildNavigationList(context, isSidebar: true),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Builder(
                                builder: (BuildContext c) => webview(context),
                              ),
                              progress < 1.0
                                  ? LinearProgressIndicator(value: progress)
                                  : Container(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : (_isMenuOpen
                  ? Material(
                      color: Theme.of(context).cardColor,
                      child: buildNavigationList(context, isSidebar: false),
                    )
                  : Column(
                      children: <Widget>[
                        Expanded(
                          child: Stack(
                            children: [
                              Builder(
                                builder: (BuildContext c) => webview(context),
                              ),
                              progress < 1.0
                                  ? LinearProgressIndicator(value: progress)
                                  : Container(),
                            ],
                          ),
                        ),
                      ],
                    )),
      ),
    );
  }
}
