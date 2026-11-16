import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

class LocaleController {
  static const String _keyLocale = 'app_locale';
  static const Locale autoLocale = Locale('auto');
  static final ValueNotifier<Locale?> currentLocale = ValueNotifier<Locale?>(
    null,
  );

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('de'),
    Locale('fr'),
    Locale('ja'),
    Locale('lt'),
    Locale('pt'),
    Locale('zh'),
  ];

  static String languageDisplayName(Locale? locale) {
    if (locale == null) return 'System Default';
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'ja':
        return '日本語';
      case 'lt':
        return 'Lietuvių';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文 (简体)';
      default:
        return locale.toLanguageTag();
    }
  }

  static String? localeKey(Locale? locale) {
    if (locale == null) return null;
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode!.toLowerCase()}';
    }
    return locale.languageCode;
  }

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_keyLocale);
      if (code != null && code.isNotEmpty) {
        currentLocale.value = Locale(code);
      }
    } catch (_) {}
  }

  static Future<void> setLocale(Locale? locale) async {
    final effective =
        (locale == null ||
            locale == autoLocale ||
            locale.languageCode == 'auto')
        ? null
        : locale;
    currentLocale.value = effective;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (effective == null) {
        await prefs.remove(_keyLocale);
      } else {
        await prefs.setString(_keyLocale, effective.languageCode);
      }
    } catch (_) {}
  }
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}

Future<String> loadLocalizedHtmlAsset(
  BuildContext context,
  String baseName,
) async {
  final cleanName = baseName.endsWith('.html')
      ? baseName.substring(0, baseName.length - 5)
      : baseName;
  final locale = Localizations.localeOf(context).languageCode;
  if (locale != 'en') {
    try {
      return await rootBundle.loadString('assets/${cleanName}_$locale.html');
    } catch (_) {
      // Fall back to default English document
    }
  }
  return await rootBundle.loadString('assets/$cleanName.html');
}

/// A standard reusable language selection button for the app bar across screens.
class LanguageMenuButton extends StatelessWidget {
  final Key? buttonKey;
  final VoidCallback? onLocaleChanged;

  const LanguageMenuButton({super.key, this.buttonKey, this.onLocaleChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, currentLocale, _) {
        return PopupMenuButton<Locale>(
          key: buttonKey ?? const ValueKey('language-switcher-btn'),
          icon: const Icon(Icons.language_rounded),
          tooltip: context.l10n.switchLanguageTooltip,
          initialValue: currentLocale ?? LocaleController.autoLocale,
          onSelected: (loc) {
            LocaleController.setLocale(loc);
            onLocaleChanged?.call();
          },
          itemBuilder: (context) => [
            CheckedPopupMenuItem<Locale>(
              value: LocaleController.autoLocale,
              checked: currentLocale == null,
              child: Text(context.l10n.languageAuto),
            ),
            ...LocaleController.supportedLocales.map(
              (locale) => CheckedPopupMenuItem<Locale>(
                value: locale,
                checked: currentLocale?.languageCode == locale.languageCode,
                child: Text(LocaleController.languageDisplayName(locale)),
              ),
            ),
          ],
        );
      },
    );
  }
}
