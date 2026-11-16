import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

import 'printer.dart';
import 'settings.dart';

class SavableColor extends Savable<Color> {
  final Color Function(ColorScheme) reset;
  VoidCallback? callback;

  SavableColor(super.name, super.description, super.value, this.reset);

  @override
  void load(SharedPreferencesWithCache prefs) {
    Log.settings.log("Loading $name as ${prefs.getInt(name)}");
    value = Color(prefs.getInt(name) ?? value.toARGB32());
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    Log.settings.log("Saving $name as ${value.toARGB32()}");
    prefs.setInt(name, value.toARGB32());
  }

  @override
  void updateTheme(ColorScheme scheme) {
    Color old = value;
    value = reset(scheme);
    Log.settings.log("updating color for $name from $old to $value");
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('$description: '),
          ColorIndicator(
            width: 30,
            height: 30,
            borderRadius: 15,
            color: value,
            elevation: 1,
            onSelectFocus: false,
            onSelect: () async {
              await pickColor(context);
              callback?.call();
              rebuild();
            },
          ),
        ],
      ),
    ];
  }

  Future<void> pickColor(BuildContext context) async {
    Color original = value;
    final Color newColor = await showColorPickerDialog(
      context,
      value,
      title: Text('Pick', style: Theme.of(context).textTheme.titleLarge),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 0,
      wheelDiameter: 165,
      enableOpacity: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: <ColorPickerType, bool>{ColorPickerType.wheel: true},
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
      ),
      actionButtons: const ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: false,
      ),
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> a1,
            Animation<double> a2,
            Widget widget,
          ) {
            final double curvedValue =
                Curves.easeInOutBack.transform(a1.value) - 1.0;
            return Transform(
              transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
              child: Opacity(opacity: a1.value, child: widget),
            );
          },
      transitionDuration: const Duration(milliseconds: 400),
      constraints: const BoxConstraints(
        minHeight: 480,
        minWidth: 320,
        maxWidth: 320,
      ),
    );
    value = newColor;
    Log.settings.log("After picking $name, color=$value, original = $original");
    callback?.call();
  }
}

class SavableColorArray extends Savable<List<Color>> {
  final List<Color> Function(ColorScheme) reset;

  SavableColorArray(super.name, super.description, super.value, this.reset);

  @override
  void load(SharedPreferencesWithCache prefs) {
    for (int i = 0; i < value.length; i++) {
      String key = "$name $i";
      Log.settings.log("Loading '$key' as ${prefs.getInt(key)}");
      value[i] = Color(prefs.getInt(key) ?? value[i].toARGB32());
    }
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    for (int i = 0; i < value.length; i++) {
      String key = "$name $i";
      Log.settings.log("Saving $key as ${value[i].toARGB32()}");
      prefs.setInt(key, value[i].toARGB32());
    }
  }

  @override
  void updateTheme(ColorScheme scheme) {
    Log.settings.log(
      "Update theme for $name. using scheme.brightness = ${scheme.brightness}",
    );
    value = List.from(reset(scheme));
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    if (value.isEmpty) {
      return [Text('$description: ')];
    }
    List<Widget> children = [];
    children.add(
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('$description: '),
          ColorIndicator(
            width: 30,
            height: 30,
            borderRadius: 15,
            color: value[0],
            elevation: 1,
            onSelectFocus: false,
            onSelect: () async {
              await pickColor(context, 0);
              rebuild();
            },
          ),
        ],
      ),
    );
    for (int i = 1; i < value.length; i++) {
      children.add(
        ColorIndicator(
          width: 30,
          height: 30,
          borderRadius: 15,
          color: value[i],
          elevation: 1,
          onSelectFocus: false,
          onSelect: () async {
            await pickColor(context, i);
            rebuild();
          },
        ),
      );
    }
    return children;
  }

  Future<void> pickColor(BuildContext context, int i) async {
    Color original = value[i];
    Log.settings.log("Picking color for $name $i");

    final Color newColor = await showColorPickerDialog(
      context,
      value[i],
      title: Text(
        'Pick $name $i',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 0,
      wheelDiameter: 165,
      enableOpacity: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: <ColorPickerType, bool>{ColorPickerType.wheel: true},
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
      ),
      actionButtons: const ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: false,
      ),
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> a1,
            Animation<double> a2,
            Widget widget,
          ) {
            final double curvedValue =
                Curves.easeInOutBack.transform(a1.value) - 1.0;
            return Transform(
              transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
              child: Opacity(opacity: a1.value, child: widget),
            );
          },
      transitionDuration: const Duration(milliseconds: 400),
      constraints: const BoxConstraints(
        minHeight: 480,
        minWidth: 320,
        maxWidth: 320,
      ),
    );
    value[i] = newColor;
    Log.settings.log(
      "After picking $name $i, color=$newColor, original = $original",
    );
  }
}

class SavableTheme extends Savable<int> with WidgetsBindingObserver {
  VoidCallback _callback = () {};

  Brightness _sysBrightness = ui.PlatformDispatcher.instance.platformBrightness;
  SavableColor themeColor = SavableColor(
    "theme_color",
    "Theme Color",
    Colors.purple,
    (scheme) => scheme.primary,
  );
  SavableColor backgroundColor = SavableColor(
    "backgroud_color",
    "Background Color",
    Colors.black,
    (scheme) => scheme.surface,
  );
  ColorScheme _scheme = const ColorScheme.light();
  ThemeMode themeMode = ThemeMode.system;
  ThemeData themeData = ThemeData.light();

  ColorScheme get scheme => _scheme;

  SavableTheme() : super("theme", "The color theme", Brightness.light.index) {
    update(updateBgColor: true);
  }

  void initialize(VoidCallback callback, [BuildContext? context]) {
    _callback = callback;
    _sysBrightness = context != null
        ? (MediaQuery.maybeOf(context)?.platformBrightness ??
              ui.PlatformDispatcher.instance.platformBrightness)
        : ui.PlatformDispatcher.instance.platformBrightness;
    themeColor.callback = updateThemeColorAndCallback;
    backgroundColor.callback = updateBgColorAndCallback;
    update(updateBgColor: true);
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    Log.settings.log("Finished with theme initialize.......................");
  }

  @override
  void didChangePlatformBrightness() {
    _sysBrightness = ui.PlatformDispatcher.instance.platformBrightness;
    if (themeMode == ThemeMode.system) {
      updateAndCallback();
    }
  }

  @override
  void load(SharedPreferencesWithCache prefs) {
    try {
      themeMode =
          ThemeMode.values[prefs.getInt("theme_mode") ?? themeMode.index];
      Log.settings.log("Theme mode = $themeMode");
    } catch (e) {
      Log.settings.log("Bad theme value? ${prefs.getInt("theme_mode")}");
    }
    themeColor.load(prefs);
    update(updateBgColor: true);
    backgroundColor.load(prefs);
    update(updateBgColor: false);
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    Log.settings.log("Setting theme_mode as ${themeMode.index}");
    prefs.setInt("theme_mode", themeMode.index);
    themeColor.save(prefs);
    backgroundColor.save(prefs);
  }

  @override
  void updateTheme(ColorScheme scheme) {
    Log.settings.log("--- Updating theme for theme.");
    update(updateBgColor: true);
  }

  void update({bool updateBgColor = true}) {
    Brightness brightness = _sysBrightness;
    if (themeMode == ThemeMode.light) brightness = Brightness.light;
    if (themeMode == ThemeMode.dark) brightness = Brightness.dark;
    Log.settings.log(
      "update theme from color ${themeColor.value}, brightness=$brightness.",
    );
    _scheme = ColorScheme.fromSeed(
      seedColor: themeColor.value,
      brightness: brightness,
    );
    if (updateBgColor) {
      backgroundColor.value = _scheme.surface;
    }
    themeData = ThemeData(
      brightness: brightness,
      colorScheme: _scheme,
      useMaterial3: true,
      canvasColor: _scheme.surface,
      cardColor: _scheme.surface,
      scaffoldBackgroundColor: _scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: _scheme.surface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _scheme.primaryContainer,
          foregroundColor: _scheme.onPrimaryContainer,
        ),
      ),
    );
    Log.settings.log("--- scheme.brightness = ${scheme.brightness}");
    Log.settings.log("--- surface = ${scheme.surface}.");
    Log.settings.log("--- onSurface = ${scheme.onSurface}.");
    Log.settings.log("--- primary = ${scheme.primary}.");
    Log.settings.log("--- secondary = ${scheme.secondary}.");
    Log.settings.log("--- tertiary = ${scheme.tertiary}.");
  }

  void updateThemeColorAndCallback() {
    update(updateBgColor: true);
    _callback.call();
  }

  void updateBgColorAndCallback() {
    update(updateBgColor: false);
    _callback.call();
  }

  void updateAndCallback() {
    update(updateBgColor: true);
    _callback.call();
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [
      switcher(context, rebuild),
      for (var w in themeColor.build(context, rebuild)) w,
      for (var w in backgroundColor.build(context, rebuild)) w,
      null,
    ];
  }

  Widget switcher(BuildContext context, VoidCallback callback) {
    List<bool> isSelected = List<bool>.filled(ThemeMode.values.length, false);
    isSelected[themeMode.index] = true;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Theme Brightness: '),
        const SizedBox(width: 10),
        ToggleButtons(
          isSelected: isSelected,
          onPressed: (int index) {
            themeMode = ThemeMode.values[index];
            Log.settings.log("switcher changed.");
            updateAndCallback();
            callback();
          },
          children: ThemeMode.values.map((e) => Text(e.name)).toList(),
        ),
      ],
    );
  }
}
