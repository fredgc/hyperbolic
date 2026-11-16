import 'package:flutter/material.dart';

import 'l10n/l10n_extension.dart';
import 'my_app.dart';
import 'printer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.initialize();

  Log.fullApp();
  final app = MyApp.fullApp();
  await app.initialize();
  runApp(app.build());
}
