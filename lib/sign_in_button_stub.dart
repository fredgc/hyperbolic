import 'dart:async';

import 'package:flutter/material.dart';
import "printer.dart";

typedef HandleSignInFn = Future<void> Function();

Widget buildSignInButton({HandleSignInFn? onPressed}) {
  Log.errors.log("--- XXX --- this is just the stub. SHOULD NOT SEE THIS!!!! ");
  return Container();
}
