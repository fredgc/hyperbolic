import 'package:flutter/material.dart';

import 'sign_in_button_stub.dart';
import "printer.dart";

Widget buildSignInButton({HandleSignInFn? onPressed}) {
  Log.drive.log("BLUE: Android sign in button.");
  return ElevatedButton(onPressed: onPressed, child: const Text('SIGN IN'));
}
