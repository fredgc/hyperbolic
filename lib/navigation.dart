import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'printer.dart';

void popOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go("/scene");
  }
}

bool isTopWidget(BuildContext context) {
  return (ModalRoute.of(context)?.isCurrent ?? false);
}

void fixAddressBar(BuildContext context, String path) {
  if (ModalRoute.of(context)?.isCurrent ?? false) {
    Future.delayed(const Duration(milliseconds: 100), () {
      SystemNavigator.routeInformationUpdated(uri: Uri.parse(path));
    });
  }
}

void dumpNavigator(BuildContext context, String source) {
  try {
    final navigator = Navigator.of(context);
    Log.dump.log(
      "MAGENTA: in $source. Navigator = $navigator, "
      "${navigator.widget.pages.length} pages",
    );
    for (Page p in navigator.widget.pages) {
      Log.dump.log(
        "   Page. name=${p.name}, arguments = ${trunc(p.arguments)}, "
        "canPop=${p.canPop}",
      );
    }
    if (ModalRoute.of(context) == null) {
      Log.dump.log("no modal route.");
    } else {
      final settings = ModalRoute.of(context)!.settings;
      final arguments = settings.arguments;
      Log.dump.log("route settings = ${trunc(settings)}");
      Log.dump.log(
        "route arguments = ${trunc(arguments)}, isCurrent = ${ModalRoute.of(context)?.isCurrent}",
      );
    }
  } catch (ex) {
    Log.errors.log("$source dump error: $ex");
  }
}
