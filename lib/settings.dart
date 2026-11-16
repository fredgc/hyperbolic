import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'color.dart';
import 'l10n/l10n_extension.dart';
import 'navigation.dart';
import 'printer.dart';
import 'js_stub.dart' if (dart.library.html) 'js_interface.dart';

enum SettingsStatus { notInitialized, initialized }

abstract class Savable<T> {
  final String name;
  final String description;
  final String tip;
  T value;

  bool visible = true;
  bool debugOnly = false;

  Savable(
    this.name,
    this.description,
    this.value, {
    this.tip = "",
    this.debugOnly = false,
  });

  void load(SharedPreferencesWithCache prefs);
  void save(SharedPreferencesWithCache prefs);

  void updateTheme(ColorScheme scheme) {}

  List<Widget?> build(BuildContext context, VoidCallback rebuild);
  void dispose() {}

  @override
  String toString() {
    return "Savable $name ($description) value=$value";
  }
}

class SavableBool extends Savable<bool> {
  SavableBool(
    super.name,
    super.description,
    super.value, {
    super.tip = "",
    super.debugOnly,
  });

  @override
  void load(SharedPreferencesWithCache prefs) {
    value = prefs.getBool(name) ?? value;
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    prefs.setBool(name, value);
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$description: "),
          Checkbox(
            value: value,
            onChanged: (bool? value) {
              this.value = value!;
              rebuild();
            },
          ),
        ],
      ),
    ];
  }
}

class SavableDouble extends Savable<double> {
  TextEditingController? _controller;

  SavableDouble(super.name, super.description, super.value, {super.tip = ""});

  @override
  void load(SharedPreferencesWithCache prefs) {
    value = prefs.getDouble(name) ?? value;
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    try {
      if (_controller != null) {
        value = double.parse(_controller!.text);
      }
    } catch (ex) {
      Log.settings.log("Parse error in ${_controller!.text} for $name");
    }
    prefs.setDouble(name, value);
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    _controller = TextEditingController();
    _controller!.text = value.toString();
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$description: "),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: tip),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}

class SavableInt extends Savable<int> {
  TextEditingController? _controller;

  SavableInt(super.name, super.description, super.value, {super.tip = ""});

  @override
  void load(SharedPreferencesWithCache prefs) {
    value = prefs.getInt(name) ?? value;
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    try {
      if (_controller != null) {
        value = int.parse(_controller!.text);
      }
    } catch (ex) {
      Log.settings.log("Parse error in ${_controller!.text} for $name");
    }
    prefs.setInt(name, value);
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    _controller = TextEditingController();
    _controller!.text = value.toString();
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$description: "),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: tip),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}

class EndOfGroup extends Savable<int> {
  static int count = 0;
  EndOfGroup() : super("row $count", "UI Feature", count++);

  @override
  void load(SharedPreferencesWithCache prefs) {}
  @override
  void save(SharedPreferencesWithCache prefs) {}

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [null];
  }
}

class SavableBoolGroup extends Savable<int> {
  final List<SavableBool> items;

  SavableBoolGroup(String name, String description, this.items)
    : super(name, description, 0);

  @override
  void load(SharedPreferencesWithCache prefs) {}

  @override
  void save(SharedPreferencesWithCache prefs) {}

  void turnAllOn(VoidCallback rebuild) {
    for (var item in items) {
      item.value = true;
    }
    rebuild();
  }

  void turnAllOff(VoidCallback rebuild) {
    for (var item in items) {
      item.value = false;
    }
    rebuild();
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$description: "),
          ElevatedButton(
            onPressed: () => turnAllOn(rebuild),
            child: const Text("Turn All On"),
          ),
        ],
      ),
      ElevatedButton(
        onPressed: () => turnAllOff(rebuild),
        child: const Text("Turn All Off"),
      ),
    ];
  }
}

class Settings {
  static SavableBool enableDebug = SavableBool(
    "enable_debug",
    "Enable Debug Mode",
    false,
    tip: "Enable debug settings and controls.",
  );

  static const bool kDebugEnabled =
      foundation.kDebugMode ||
      bool.fromEnvironment('DEBUG_ENABLED', defaultValue: false);

  static bool get debugEnabled => kDebugEnabled && enableDebug.value;

  SettingsStatus _status = SettingsStatus.notInitialized;
  final StreamController<SettingsStatus> _statusStream =
      StreamController<SettingsStatus>.broadcast();

  String appName = "uninitialized";
  String version = "uninitialized";
  String buildNumber = "-";
  bool noKeyboard = false;
  Future<void>? _loadingFuture;

  String get fullVersion {
    if (version == "uninitialized") return "1.0.0+1";
    if (buildNumber.isNotEmpty && buildNumber != "-") {
      return "$version+$buildNumber";
    }
    return version;
  }

  List<Savable> savables = [];
  Map<String, Savable> savablesMap = {};

  SavableTheme theme = SavableTheme();
  Color get backgroundColor => theme.backgroundColor.value;

  Settings();

  void initDebug() {
    if (kDebugEnabled) {
      add(EndOfGroup());
      add(enableDebug);
    }
  }

  Future<void>? _initializeFuture;
  Future<void> initialize([BuildContext? context]) {
    return _initializeFuture ??= _doInitialize(context);
  }

  Future<void> _doInitialize([BuildContext? context]) {
    _checkKeyboard();
    theme.initialize(resetColorsAndNotify, context);
    resetColors();
    return load();
  }

  void _checkKeyboard() {
    noKeyboard =
        (foundation.defaultTargetPlatform == TargetPlatform.iOS ||
        foundation.defaultTargetPlatform == TargetPlatform.android);
  }

  SettingsStatus get status => _status;

  set status(SettingsStatus newStatus) {
    _status = newStatus;
    if (_statusStream.hasListener) _statusStream.add(_status);
  }

  Stream<SettingsStatus> statusStream() async* {
    yield _status;
    yield* _statusStream.stream;
  }

  void addTheme() {
    add(theme);
  }

  void add(Savable savable) {
    savables.add(savable);
  }

  Future<void> load() {
    _loadingFuture ??= _loadFuture();
    return _loadingFuture!;
  }

  Future<SharedPreferencesWithCache> getPrefs() {
    var options = const SharedPreferencesWithCacheOptions();
    return SharedPreferencesWithCache.create(cacheOptions: options);
  }

  Future<void> _loadFuture() async {
    Log.settings.log("In _loadFuture.");
    await dsleep("settings", 3);
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appName = packageInfo.appName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
      Log.settings.log("Package info: $appName, $buildNumber, $version");
    } catch (e) {
      Log.settings.log("Error loading package info: $e");
    }
    var prefs = await getPrefs();
    theme.load(prefs);
    resetColors();
    for (var s in savables) {
      s.load(prefs);
    }
    Log.settings.log("Settings done initialized.");
    status = SettingsStatus.initialized;
    _loadingFuture = null;
    Log.settings.log("Finished loading settings.");

    if (foundation.kIsWeb) {
      unawaited(checkServerVersionAndReload());
    }
  }

  Future<void> checkServerVersionAndReload() async {
    try {
      final uri = Uri.parse(
        "version.json?nocache=${DateTime.now().millisecondsSinceEpoch}",
      );
      final response = await http.get(
        uri,
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? serverVer = data['version'];
        final String? serverBuild = data['build_number'];
        final String? serverVersion =
            (serverBuild != null && serverBuild.isNotEmpty && serverVer != null)
            ? '$serverVer+$serverBuild'
            : serverVer;
        final String clientVersion = "$version+$buildNumber";
        Log.settings.log(
          "Server version check: client=$clientVersion, server=$serverVersion",
        );
        if (serverVersion != null &&
            serverVersion.isNotEmpty &&
            serverVersion != clientVersion &&
            serverVersion != version) {
          Log.settings.log(
            "PURPLE: Server version ($serverVersion) differs from client ($clientVersion). Auto reloading...",
          );
          await reloadAndFlushCache();
        }
      }
    } catch (e) {
      Log.settings.log("Error checking server version: $e");
    }
  }

  Future<void> save() async {
    final prefs = await getPrefs();
    for (var s in savables) {
      s.save(prefs);
    }
  }

  void notify() {
    if (_statusStream.hasListener) _statusStream.add(_status);
  }

  void resetColorsAndNotify() {
    resetColors();
    notify();
  }

  void resetColors() {
    for (var s in savables) {
      s.updateTheme(theme.scheme);
    }
  }
}

class SettingsScreen extends StatefulWidget {
  final Settings settings;
  static const routeName = "/settings";
  const SettingsScreen(this.settings, {super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late StreamSubscription _statusListener;

  @override
  void initState() {
    super.initState();
    _statusListener = widget.settings.statusStream().listen((status) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _statusListener.cancel();
    for (var s in widget.settings.savables) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settings.status == SettingsStatus.notInitialized) {
      widget.settings.initialize(context).then((_) {
        setState(() {});
      });
      return const Text("Initializing Settings...");
    }
    List<Widget?> children = _pickChildren(context);
    List<List<Widget>> rows = [for (var s in MyIterator(children)) s];
    final list = ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: rows.length,
      itemBuilder: (buildContext, int index) {
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: rows[index],
        );
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
    return Scaffold(appBar: appBar(context), body: list);
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: Text(context.l10n.settingsTitle),
      actions: <Widget>[
        LanguageMenuButton(
          buttonKey: const ValueKey('settings-language-switcher-btn'),
          onLocaleChanged: () => setState(() {}),
        ),
        ElevatedButton(
          child: const Icon(Icons.close),
          onPressed: () {
            quit(context);
          },
        ),
        ElevatedButton(
          child: const Icon(Icons.done),
          onPressed: () {
            done(context);
          },
        ),
      ],
    );
  }

  List<Widget?> _pickChildren(BuildContext context) {
    if (widget.settings.status == SettingsStatus.notInitialized) {
      return [const Text("Initializing App...")];
    }
    List<List<Widget?>> list1 = [
      [
        SelectableText(
          "Application ${widget.settings.appName} "
          "version ${widget.settings.version}.${widget.settings.buildNumber}",
        ),
        if (foundation.kIsWeb) ...[
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Clear Cache & Reload App"),
            onPressed: () => reloadAndFlushCache(),
          ),
        ],
        null,
      ],
      for (var s in widget.settings.savables)
        if (s.visible && (!s.debugOnly || Settings.debugEnabled))
          (s.build(context, () {
            setState(() {});
          })),
      [
        null,
        ElevatedButton(
          onPressed: () => done(context),
          child: const Text("Done"),
        ),
        ElevatedButton(
          onPressed: () => quit(context),
          child: const Text("Cancel"),
        ),
      ],
    ];
    return [
      for (var sublist in list1)
        for (var w in sublist) w,
    ];
  }

  void done(BuildContext context) async {
    await widget.settings.save();
    widget.settings.notify();
    if (!context.mounted) return;
    popOrHome(context);
  }

  void quit(BuildContext context) async {
    await widget.settings.load();
    widget.settings.notify();
    if (!context.mounted) return;
    popOrHome(context);
  }
}

class MyIterator extends Iterable<List<Widget>>
    implements Iterator<List<Widget>> {
  List<Widget?> input;
  List<Widget> _current = [];
  @override
  List<Widget> get current => _current;
  @override
  Iterator<List<Widget>> get iterator => this;

  MyIterator(this.input);

  @override
  bool moveNext() {
    while (input.isNotEmpty) {
      int i = input.indexWhere((s) => s == null);
      if (i < 0) {
        _current = input.nonNulls.toList();
        input = [];
      } else {
        _current = input.sublist(0, i).nonNulls.toList();
        input = input.sublist(i + 1);
      }
      if (_current.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
